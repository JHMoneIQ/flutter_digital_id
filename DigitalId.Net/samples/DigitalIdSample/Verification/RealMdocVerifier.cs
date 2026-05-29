using DigitalId;
using Org.BouncyCastle.Crypto;
using Org.BouncyCastle.Crypto.Parameters;
using Org.BouncyCastle.Security;

namespace DigitalIdSample.Verification;

/// <summary>
/// More complete mdoc verification example using BouncyCastle.
/// This lives in the sample so the core DigitalId.Net package stays minimal.
/// 
/// In production you would combine this with a CBOR library (PeterO.Cbor recommended)
/// to parse the actual mdoc bytes.
/// </summary>
public static class RealMdocVerifier
{
    public static bool VerifyDeviceAuthUsingCoseSign1(byte[] coseSign1Bytes, AsymmetricKeyParameter devicePublicKey, byte[] sessionTranscript)
    {
        // In real code: parse coseSign1Bytes with CBOR to populate CoseSign1
        // For this sample we assume the caller has done the parsing.
        // Here we just show the cryptographic verification step.

        // Placeholder - real implementation would construct CoseSign1 from parsed data
        return false;
    }

    /// <summary>
    /// Example of full device authentication flow (what you would call after parsing the mdoc).
    /// </summary>
    public static bool VerifyDeviceAuthentication(AsymmetricKeyParameter devicePublicKey, byte[] transcriptHash, byte[] signature)
    {
        try
        {
            ISigner signer = SignerUtilities.GetSigner("SHA-256withECDSA");
            signer.Init(false, devicePublicKey);
            signer.BlockUpdate(transcriptHash, 0, transcriptHash.Length);
            return signer.VerifySignature(signature);
        }
        catch
        {
            return false;
        }
    }
}
