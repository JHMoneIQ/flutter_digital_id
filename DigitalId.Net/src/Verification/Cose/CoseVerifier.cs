using Org.BouncyCastle.Crypto;
using Org.BouncyCastle.Crypto.Parameters;
using Org.BouncyCastle.Security;
using PeterO.Cbor;
using System;

namespace DigitalId.Verification.Cose;

public static class CoseVerifier
{
    public static bool VerifySign1(byte[] coseBytes, AsymmetricKeyParameter publicKey, byte[] externalData)
    {
        var cbor = CBORObject.DecodeFromBytes(coseBytes);

        byte[] protectedHeader = cbor[0].GetByteString();
        byte[]? payload = cbor[2].IsNull ? null : cbor[2].GetByteString();
        byte[] signature = cbor[3].GetByteString();

        var sign1 = new CoseSign1(protectedHeader, Array.Empty<byte>(), payload, signature);

        ISigner signer = SignerUtilities.GetSigner("SHA-256withECDSA");
        signer.Init(false, publicKey);

        return sign1.Verify(signer, externalData);
    }

    public static bool VerifyMac0(byte[] coseBytes, byte[] macKey, byte[] externalData)
    {
        var cbor = CBORObject.DecodeFromBytes(coseBytes);

        byte[] protectedHeader = cbor[0].GetByteString();
        byte[]? payload = cbor[2].IsNull ? null : cbor[2].GetByteString();
        byte[] tag = cbor[3].GetByteString();

        var mac0 = new CoseMac0(protectedHeader, Array.Empty<byte>(), payload, tag);

        IMac mac = MacUtilities.GetMac("HMACSHA256");
        mac.Init(new KeyParameter(macKey));

        return mac0.Verify(mac, externalData);
    }
}
