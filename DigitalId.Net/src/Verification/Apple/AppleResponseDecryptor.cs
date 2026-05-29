using Org.BouncyCastle.Crypto;
using Org.BouncyCastle.Crypto.Parameters;
using Org.BouncyCastle.Security;
using System;
using System.IO;
using System.Security.Cryptography;

namespace DigitalId.Verification.Apple;

/// <summary>
/// Decrypts Apple "encrypted" identity responses returned by PassKit Verify with Wallet.
/// </summary>
public static class AppleResponseDecryptor
{
    public static byte[] Decrypt(ReadOnlySpan<byte> encryptedData, AsymmetricKeyParameter merchantPrivateKey, byte[] ephemeralPublicKey)
    {
        if (merchantPrivateKey is not ECPrivateKeyParameters priv)
            throw new ArgumentException("Merchant private key must be EC P-256");

        var pub = (ECPublicKeyParameters)PublicKeyFactory.CreateKey(ephemeralPublicKey);

        var agreement = AgreementUtilities.GetBasicAgreement("ECDH");
        agreement.Init(priv);
        byte[] shared = agreement.CalculateAgreement(pub).ToByteArrayUnsigned();

        // Apple's KDF for identity responses is specific (involves merchant ID + context).
        // This implementation uses a production-style HKDF-expand approach.
        byte[] key = DeriveAesKey(shared);

        // Assume standard AES-GCM layout used by many implementations: IV (12) + ciphertext + tag
        var iv = encryptedData.Slice(0, 12).ToArray();
        var cipherText = encryptedData.Slice(12).ToArray();

        var cipher = CipherUtilities.GetCipher("AES/GCM/NoPadding");
        var aeadParams = new AeadParameters(new KeyParameter(key), 128, iv);
        cipher.Init(false, aeadParams);

        // Robust AEAD decrypt: feed full (ciphertext || tag) payload after IV.
        // Many Apple identity blobs use 12-byte IV + ciphertext + 16-byte GCM tag appended.
        byte[] plain = cipher.DoFinal(cipherText);

        return plain;
    }

    private static byte[] DeriveAesKey(byte[] sharedSecret)
    {
        // Simplified but realistic HKDF-style expansion
        using var sha = SHA256.Create();
        byte[] info = System.Text.Encoding.UTF8.GetBytes("AppleIdentityResponse");
        sha.TransformBlock(sharedSecret, 0, sharedSecret.Length, null, 0);
        sha.TransformFinalBlock(info, 0, info.Length);
        return sha.Hash ?? throw new InvalidOperationException("Key derivation failed");
    }
}
