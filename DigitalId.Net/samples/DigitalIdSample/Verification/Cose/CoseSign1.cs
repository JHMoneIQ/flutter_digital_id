// Real COSE_Sign1 implementation moved to the sample (where BouncyCastle is referenced).
// See the main library's DigitalIdVerifier for the lightweight version + guidance.

using Org.BouncyCastle.Crypto;
using Org.BouncyCastle.Security;

namespace DigitalIdSample.Verification.Cose;

public sealed class CoseSign1
{
    public byte[] ProtectedHeader { get; }
    public byte[] Payload { get; }
    public byte[] Signature { get; }

    public CoseSign1(byte[] protectedHeader, byte[]? payload, byte[] signature)
    {
        ProtectedHeader = protectedHeader;
        Payload = payload ?? Array.Empty<byte>();
        Signature = signature;
    }

    public bool Verify(ISigner signer, byte[] externalData)
    {
        byte[] toBeSigned = BuildSigStructure(externalData);
        signer.BlockUpdate(toBeSigned, 0, toBeSigned.Length);
        return signer.VerifySignature(Signature);
    }

    private byte[] BuildSigStructure(byte[] externalData)
    {
        using var ms = new MemoryStream();
        ms.Write(System.Text.Encoding.UTF8.GetBytes("Signature1"));
        ms.Write(ProtectedHeader);
        ms.Write(externalData);
        ms.Write(Payload);
        return ms.ToArray();
    }
}
