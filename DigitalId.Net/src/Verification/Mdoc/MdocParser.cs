using PeterO.Cbor;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;

namespace DigitalId.Verification.Mdoc;

/// <summary>
/// Production-grade parser for mdoc ISO 18013-5 DeviceResponse.
/// Extracts IssuerAuth (COSE_Sign1 containing MSO), DeviceAuth, issuerNameSpaces (disclosed claims),
/// and parses the Mobile Security Object (MSO) for digest validation.
/// </summary>
public static class MdocParser
{
    /// <summary>
    /// Parses a DeviceResponse CBOR into a rich MdocDocument with MSO and disclosed namespaces extracted.
    /// </summary>
    public static MdocDocument ParseDeviceResponse(ReadOnlySpan<byte> deviceResponseBytes)
    {
        var cbor = CBORObject.DecodeFromBytes(deviceResponseBytes.ToArray());

        if (!cbor.ContainsKey("documents") || cbor["documents"].Count == 0)
            throw new ArgumentException("No documents in DeviceResponse");

        var doc = cbor["documents"][0];
        var issuerSigned = doc["issuerSigned"];
        var issuerAuthBytes = issuerSigned["issuerAuth"].GetByteString();

        var deviceSigned = doc["deviceSigned"];
        var deviceAuth = deviceSigned["deviceAuth"];

        // Extract disclosed issuerNameSpaces (map of namespace -> array of {digestID, elementIdentifier, elementValue})
        CBORObject? issuerNameSpaces = null;
        if (issuerSigned.ContainsKey("issuerNameSpaces"))
            issuerNameSpaces = issuerSigned["issuerNameSpaces"];

        // Decode the MSO from inside the IssuerAuth COSE_Sign1 payload (index 2)
        byte[]? msoBytes = null;
        MdocMso? mso = null;
        try
        {
            var issuerAuthCose = CBORObject.DecodeFromBytes(issuerAuthBytes);
            if (issuerAuthCose.Count >= 4 && !issuerAuthCose[2].IsNull)
            {
                msoBytes = issuerAuthCose[2].GetByteString();
                mso = ParseMso(msoBytes);
            }
        }
        catch
        {
            // MSO parsing is best-effort; caller can still do outer signature verification
        }

        return new MdocDocument
        {
            IssuerAuth = issuerAuthBytes,
            DeviceAuth = deviceAuth,
            IssuerNameSpaces = issuerNameSpaces,
            Mso = mso,
            MsoBytes = msoBytes
        };
    }

    /// <summary>
    /// Parses the Mobile Security Object (MSO) CBOR payload.
    /// </summary>
    public static MdocMso? ParseMso(byte[] msoBytes)
    {
        if (msoBytes == null || msoBytes.Length == 0) return null;

        var mso = CBORObject.DecodeFromBytes(msoBytes);

        string version = mso.ContainsKey("version") ? mso["version"].AsString() : "1.0";
        string digestAlg = mso.ContainsKey("digestAlgorithm") ? mso["digestAlgorithm"].AsString() : "SHA-256";

        var valueDigests = new Dictionary<string, Dictionary<int, byte[]>>();
        if (mso.ContainsKey("valueDigests"))
        {
            var vdMap = mso["valueDigests"];
            foreach (var nsKey in vdMap.Keys)
            {
                string ns = nsKey.AsString();
                var perNs = new Dictionary<int, byte[]>();
                var digestsForNs = vdMap[nsKey];
                foreach (var digestIdKey in digestsForNs.Keys)
                {
                    int digestId = digestIdKey.AsInt32();
                    byte[] digest = digestsForNs[digestIdKey].GetByteString();
                    perNs[digestId] = digest;
                }
                valueDigests[ns] = perNs;
            }
        }

        CBORObject? deviceKeyInfo = mso.ContainsKey("deviceKeyInfo") ? mso["deviceKeyInfo"] : null;
        CBORObject? validityInfo = mso.ContainsKey("validityInfo") ? mso["validityInfo"] : null;

        return new MdocMso
        {
            Version = version,
            DigestAlgorithm = digestAlg,
            ValueDigests = valueDigests,
            DeviceKeyInfo = deviceKeyInfo,
            ValidityInfo = validityInfo,
            RawMso = msoBytes
        };
    }

    /// <summary>
    /// Validates that every disclosed element in issuerNameSpaces has a matching digest entry in the MSO valueDigests.
    /// This is the critical security check that the issuer actually signed/authored the exact disclosed claim values.
    /// </summary>
    public static (bool IsValid, string? Error) ValidateDigests(MdocDocument doc)
    {
        if (doc.Mso == null)
            return (false, "No MSO present in IssuerAuth payload");

        if (doc.IssuerNameSpaces == null || doc.IssuerNameSpaces.Count == 0)
            return (true, null); // Nothing disclosed under issuer signing — valid (device-only claims possible)

        string alg = doc.Mso.DigestAlgorithm;
        if (!string.Equals(alg, "SHA-256", StringComparison.OrdinalIgnoreCase))
            return (false, $"Unsupported digestAlgorithm in MSO: {alg}");

        var disclosed = doc.IssuerNameSpaces;
        foreach (var nsKey in disclosed.Keys)
        {
            string ns = nsKey.AsString();
            var entries = disclosed[nsKey];
            if (!doc.Mso.ValueDigests.TryGetValue(ns, out var expectedDigestsForNs))
                return (false, $"MSO missing valueDigests for disclosed namespace: {ns}");

            for (int i = 0; i < entries.Count; i++)
            {
                var entry = entries[i];
                int digestId = entry["digestID"].AsInt32();
                // The digest is computed over the CBOR encoding of the elementValue
                byte[] elementValueCbor = entry["elementValue"].EncodeToBytes();
                byte[] computed = SHA256.HashData(elementValueCbor);

                if (!expectedDigestsForNs.TryGetValue(digestId, out var expected))
                    return (false, $"Missing digestID {digestId} in MSO valueDigests[{ns}]");

                if (!computed.SequenceEqual(expected))
                    return (false, $"Digest mismatch for {ns}[{digestId}] (disclosed value does not match issuer-signed MSO digest)");
            }
        }

        return (true, null);
    }
}

/// <summary>
/// Parsed Mobile Security Object from the IssuerAuth COSE payload.
/// </summary>
public sealed class MdocMso
{
    public string Version { get; set; } = "1.0";
    public string DigestAlgorithm { get; set; } = "SHA-256";
    public Dictionary<string, Dictionary<int, byte[]>> ValueDigests { get; set; } = new();
    public CBORObject? DeviceKeyInfo { get; set; }
    public CBORObject? ValidityInfo { get; set; }
    public byte[]? RawMso { get; set; }
}

/// <summary>
/// Rich document structure with all pieces needed for full cryptographic validation.
/// </summary>
public sealed class MdocDocument
{
    /// <summary>Raw COSE_Sign1 bytes for the issuer authorization (contains the MSO).</summary>
    public byte[]? IssuerAuth { get; set; }

    /// <summary>Device authentication structure (deviceSignature or deviceMac).</summary>
    public CBORObject? DeviceAuth { get; set; }

    /// <summary>Disclosed name spaces and values (the actual claims).</summary>
    public CBORObject? IssuerNameSpaces { get; set; }

    /// <summary>Parsed Mobile Security Object.</summary>
    public MdocMso? Mso { get; set; }

    /// <summary>Raw bytes of the MSO (for digest verification).</summary>
    public byte[]? MsoBytes { get; set; }
}
