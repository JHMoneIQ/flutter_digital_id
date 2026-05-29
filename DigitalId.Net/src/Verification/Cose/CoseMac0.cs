using PeterO.Cbor;
using System;
using System.Linq;
using Org.BouncyCastle.Crypto;

namespace DigitalId.Verification.Cose;

public sealed class CoseMac0
{
    public byte[] ProtectedHeader { get; }
    public byte[] UnprotectedHeader { get; }
    public byte[]? Payload { get; }
    public byte[] Tag { get; }

    public CoseMac0(byte[] protectedHeader, byte[] unprotectedHeader, byte[]? payload, byte[] tag)
    {
        ProtectedHeader = protectedHeader ?? throw new ArgumentNullException(nameof(protectedHeader));
        UnprotectedHeader = unprotectedHeader ?? Array.Empty<byte>();
        Payload = payload;
        Tag = tag ?? throw new ArgumentNullException(nameof(tag));
    }

    public bool Verify(IMac mac, byte[] externalData)
    {
        byte[] toBeMaced = BuildMacStructure(externalData);
        mac.BlockUpdate(toBeMaced, 0, toBeMaced.Length);
        byte[] computed = new byte[mac.GetMacSize()];
        mac.DoFinal(computed, 0);
        return Tag.SequenceEqual(computed);
    }

    private byte[] BuildMacStructure(byte[] externalData)
    {
        var structure = CBORObject.NewArray();
        structure.Add("MAC0");
        structure.Add(ProtectedHeader);
        structure.Add(externalData ?? Array.Empty<byte>());
        structure.Add(Payload ?? Array.Empty<byte>());

        return structure.EncodeToBytes();
    }
}
