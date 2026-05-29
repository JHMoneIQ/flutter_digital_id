using PeterO.Cbor;
using System;

namespace DigitalId.Verification.Cose;

/// <summary>
/// Represents a decoded COSE_Sign1 structure.
/// </summary>
public sealed class CoseSign1
{
    public byte[] ProtectedHeader { get; }
    public byte[] UnprotectedHeader { get; }
    public byte[]? Payload { get; }
    public byte[] Signature { get; }

    public CoseSign1(byte[] protectedHeader, byte[] unprotectedHeader, byte[]? payload, byte[] signature)
    {
        ProtectedHeader = protectedHeader ?? throw new ArgumentNullException(nameof(protectedHeader));
        UnprotectedHeader = unprotectedHeader ?? Array.Empty<byte>();
        Payload = payload;
        Signature = signature ?? throw new ArgumentNullException(nameof(signature));
    }

    /// <summary>
    /// Verifies the signature using the provided BouncyCastle signer.
    /// The signer must already be initialized with the public key.
    /// </summary>
    public bool Verify(Org.BouncyCastle.Crypto.ISigner signer, byte[] externalData)
    {
        byte[] toBeSigned = BuildSigStructure(externalData);
        signer.BlockUpdate(toBeSigned, 0, toBeSigned.Length);
        return signer.VerifySignature(Signature);
    }

    /// <summary>
    /// Builds the Sig_structure exactly as specified in RFC 8152 / RFC 9052.
    /// </summary>
    private byte[] BuildSigStructure(byte[] externalData)
    {
        var structure = CBORObject.NewArray();
        structure.Add("Signature1");
        structure.Add(ProtectedHeader);
        structure.Add(externalData ?? Array.Empty<byte>());
        structure.Add(Payload ?? Array.Empty<byte>());

        return structure.EncodeToBytes();
    }
}
