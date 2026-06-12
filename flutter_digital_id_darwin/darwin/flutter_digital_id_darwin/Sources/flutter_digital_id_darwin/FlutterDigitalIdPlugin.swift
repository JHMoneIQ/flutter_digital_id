import Flutter
import Foundation
import PassKit
#if os(iOS)
import UIKit
#endif

/// Darwin entry point for `flutter_digital_id`.
///
/// macOS returns clear PLATFORM_UNSUPPORTED. On iOS, this uses the documented PassKit
/// Verify with Wallet types (`PKIdentityAuthorizationController`,
/// `PKIdentityRequest`, and the typed descriptors) for the real entitled presentment flow.
public final class FlutterDigitalIdPlugin: NSObject, FlutterPlugin {
#if os(iOS)
    @available(iOS 16.0, *)
    private lazy var authorizationController = PKIdentityAuthorizationController()
#endif

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "flutter_digital_id/darwin",
            binaryMessenger: registrar.messenger()
        )
        let instance = FlutterDigitalIdPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isDigitalIdAvailable":
            handleIsAvailable(call: call, result: result)
        case "getDigitalId":
            handleGetDigitalId(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleIsAvailable(call: FlutterMethodCall, result: @escaping FlutterResult) {
        #if os(macOS)
        result(false)
        #else
        guard #available(iOS 16.0, *) else {
            result(false)
            return
        }

        guard UIDevice.current.userInterfaceIdiom == .phone else {
            result(false)
            return
        }

        guard let args = call.arguments as? [String: Any] else {
            result(false)
            return
        }

        do {
            let builtDescriptor = try buildDescriptor(from: args)
            authorizationController.checkCanRequestDocument(builtDescriptor.descriptor) { canRequest in
                result(canRequest)
            }
        } catch {
            result(false)
        }
        #endif
    }

    private func handleGetDigitalId(call: FlutterMethodCall, result: @escaping FlutterResult) {
        #if os(macOS)
        result(FlutterError(
            code: "PLATFORM_UNSUPPORTED",
            message: "In-App Identity Presentment is not supported on macOS.",
            details: nil
        ))
        #else
        guard #available(iOS 16.0, *) else {
            result(FlutterError(
                code: "PLATFORM_UNSUPPORTED",
                message: "Verify with Wallet requires iOS 16.0 or later.",
                details: nil
            ))
            return
        }

        guard UIDevice.current.userInterfaceIdiom == .phone else {
            result(FlutterError(
                code: "PLATFORM_UNSUPPORTED",
                message: "Verify with Wallet currently works on iPhone only.",
                details: nil
            ))
            return
        }

        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments.", details: nil))
            return
        }

        do {
            let builtDescriptor = try buildDescriptor(from: args)
            let options = args["options"] as? [String: Any]
            let merchantIdentifier = try resolveMerchantIdentifier(from: options)
            let nonceData = resolveNonce(from: options)

            let request = PKIdentityRequest()
            request.descriptor = builtDescriptor.descriptor
            request.merchantIdentifier = merchantIdentifier
            request.nonce = nonceData

            authorizationController.requestDocument(request) { [weak self] document, error in
                if let error {
                    self?.handlePresentationError(error, result: result)
                    return
                }

                guard let document else {
                    result(nil)
                    return
                }

                result([
                    "credentialFormat": "apple-encrypted",
                    "rawCredential": document.encryptedData.base64EncodedString(),
                    "disclosedClaimPaths": builtDescriptor.disclosedClaimPaths,
                    "metadata": [
                        "merchantIdentifier": merchantIdentifier,
                        "nonce": nonceData.base64EncodedString(),
                    ],
                ])
            }
        } catch let configError as DarwinConfigurationError {
            result(FlutterError(code: configError.code, message: configError.message, details: nil))
        } catch {
            result(FlutterError(code: "INVALID_REQUEST", message: error.localizedDescription, details: nil))
        }
        #endif
    }

#if os(iOS)
    @available(iOS 16.0, *)
    private func buildDescriptor(from args: [String: Any]) throws -> BuiltDescriptor {
        let type = DigitalIdType(rawValue: args["type"] as? Int ?? 0) ?? .passport
        let options = args["options"] as? [String: Any]
        let requiredClaims = parseClaimPaths(options?["requiredClaims"])
        let optionalClaims = parseClaimPaths(options?["optionalClaims"])
        let disclosedClaimPaths = Array(Set(requiredClaims + optionalClaims)).sorted()
        let defaultClaims = defaultClaimPaths(for: type)
        let requiredElements = buildElements(from: requiredClaims.isEmpty ? defaultClaims : requiredClaims)
        let optionalElements = buildElements(from: optionalClaims)
        let intent = buildIntentToStore(from: options)

        switch type {
        case .driversLicense, .ageVerificationOnly:
            let descriptor = PKIdentityDriversLicenseDescriptor()
            apply(elements: requiredElements, to: descriptor, intent: intent)
            apply(elements: optionalElements, to: descriptor, intent: intent)
            return BuiltDescriptor(descriptor: descriptor, disclosedClaimPaths: disclosedClaimPaths.isEmpty ? defaultClaims : disclosedClaimPaths)

        case .euDigitalId:
            guard #available(iOS 18.0, *) else {
                throw DarwinConfigurationError.unsupportedDocumentType("National ID requests require iOS 18.0 or later.")
            }

            let descriptor = PKIdentityNationalIDCardDescriptor()
            apply(elements: requiredElements, to: descriptor, intent: intent)
            apply(elements: optionalElements, to: descriptor, intent: intent)
            return BuiltDescriptor(descriptor: descriptor, disclosedClaimPaths: disclosedClaimPaths.isEmpty ? defaultClaims : disclosedClaimPaths)

        case .passport:
            guard #available(iOS 26.0, *) else {
                throw DarwinConfigurationError.unsupportedDocumentType("Photo ID / passport digital IDs require iOS 26.0 or later.")
            }

            let descriptor = PKIdentityPhotoIDDescriptor()
            apply(elements: requiredElements, to: descriptor, intent: intent)
            apply(elements: optionalElements, to: descriptor, intent: intent)
            return BuiltDescriptor(descriptor: descriptor, disclosedClaimPaths: disclosedClaimPaths.isEmpty ? defaultClaims : disclosedClaimPaths)
        }
    }

    @available(iOS 16.0, *)
    private func buildIntentToStore(from options: [String: Any]?) -> PKIdentityIntentToStore {
        ((options?["intentToRetain"] as? Bool) ?? false) ? .mayStore : .willNotStore
    }

    @available(iOS 16.0, *)
    private func apply(
        elements: [PKIdentityElement],
        to descriptor: some PKIdentityDocumentDescriptor,
        intent: PKIdentityIntentToStore
    ) {
        guard !elements.isEmpty else { return }
        descriptor.addElements(elements, intentToStore: intent)
    }

    private func parseClaimPaths(_ rawValue: Any?) -> [String] {
        ((rawValue as? [[String: Any]]) ?? []).compactMap { item in
            guard let segments = item["segments"] as? [String], !segments.isEmpty else {
                return nil
            }
            return segments.joined(separator: ".")
        }
    }

    @available(iOS 16.0, *)
    private func buildElements(from claimPaths: [String]) -> [PKIdentityElement] {
        var elements: [PKIdentityElement] = []
        for claimPath in claimPaths {
            if let element = claimPathToElement(claimPath) {
                elements.append(element)
            }
        }
        return deduplicate(elements)
    }

    @available(iOS 16.0, *)
    private func deduplicate(_ elements: [PKIdentityElement]) -> [PKIdentityElement] {
        var unique: [PKIdentityElement] = []
        for element in elements where !unique.contains(element) {
            unique.append(element)
        }
        return unique
    }

    private func defaultClaimPaths(for type: DigitalIdType) -> [String] {
        switch type {
        case .ageVerificationOnly:
            return ["org.iso.18013.5.1.age_over_18"]
        default:
            return [
                "org.iso.18013.5.1.family_name",
                "org.iso.18013.5.1.given_name",
                "org.iso.18013.5.1.birth_date",
            ]
        }
    }

    @available(iOS 16.0, *)
    private func claimPathToElement(_ claimPath: String) -> PKIdentityElement? {
        let key = claimPath.split(separator: ".").last?.lowercased() ?? claimPath.lowercased()

        switch key {
        case "given_name", "given-name":
            return .givenName
        case "family_name", "family-name":
            return .familyName
        case "birth_date", "date_of_birth", "date-of-birth":
            return .dateOfBirth
        case "portrait":
            return .portrait
        case "address":
            return .address
        case "document_number", "document-number":
            return .documentNumber
        case "document_issue_date", "document-issue-date":
            return .documentIssueDate
        case "document_expiration_date", "document-expiration-date", "expiration-date":
            return .documentExpirationDate
        case "issuing_authority", "issuing-authority":
            return .issuingAuthority
        case "driving_privileges", "driving-privileges":
            return .drivingPrivileges
        case "sex":
            if #available(iOS 17.2, *) {
                return .sex
            }
            return nil
        case "eye_colour", "eye_color", "eye-colour":
            if #available(iOS 26.0, *) {
                return .eyeColor
            }
            return nil
        case "hair_colour", "hair_color", "hair-colour":
            if #available(iOS 26.0, *) {
                return .hairColor
            }
            return nil
        case "height":
            if #available(iOS 26.0, *) {
                return .height
            }
            return nil
        case "weight":
            if #available(iOS 26.0, *) {
                return .weight
            }
            return nil
        case "organ_donor", "organ-donor", "organ_donor_status":
            if #available(iOS 26.0, *) {
                return .organDonorStatus
            }
            return nil
        case "age":
            return .age
        default:
            if let age = extractAgeThreshold(from: key) {
                return .age(atLeast: age)
            }
            return nil
        }
    }

    private func extractAgeThreshold(from key: String) -> Int? {
        guard key.hasPrefix("age_over_") else { return nil }
        return Int(key.replacingOccurrences(of: "age_over_", with: ""))
    }

    private func resolveMerchantIdentifier(from options: [String: Any]?) throws -> String {
        let platformOptions = options?["platformOptions"] as? [String: Any]

        if let merchantIdentifier = platformOptions?["merchantIdentifier"] as? String,
           !merchantIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return merchantIdentifier
        }

        if let merchantIdentifier = Bundle.main.object(forInfoDictionaryKey: "DigitalIdMerchantIdentifier") as? String,
           !merchantIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return merchantIdentifier
        }

        throw DarwinConfigurationError.invalidConfiguration(
            "Provide a merchant identifier via Info.plist key 'DigitalIdMerchantIdentifier' or options.platformOptions['merchantIdentifier']."
        )
    }

    private func resolveNonce(from options: [String: Any]?) -> Data {
        if let nonce = options?["nonce"] as? String, !nonce.isEmpty {
            return Data(nonce.utf8)
        }

        return Data(UUID().uuidString.utf8)
    }

    private func handlePresentationError(_ error: Error, result: @escaping FlutterResult) {
        let message = (error as NSError).localizedDescription.lowercased()

        if message.contains("cancel") {
            result(FlutterError(code: "userCancelled", message: "User cancelled the identity presentation.", details: nil))
            return
        }

        if message.contains("entitle") || message.contains("capability") || message.contains("merchant") {
            result(FlutterError(code: "NOT_ENTITLED", message: "Missing or invalid Verify with Wallet entitlement / merchant configuration.", details: nil))
            return
        }

        if message.contains("request") && message.contains("in progress") {
            result(FlutterError(code: "REQUEST_FAILED", message: "Another identity request is already in progress.", details: nil))
            return
        }

        result(FlutterError(code: "REQUEST_FAILED", message: (error as NSError).localizedDescription, details: nil))
    }

    @available(iOS 16.0, *)
    private struct BuiltDescriptor {
        let descriptor: any PKIdentityDocumentDescriptor
        let disclosedClaimPaths: [String]
    }
#endif

    private enum DigitalIdType: Int {
        case passport = 0
        case euDigitalId = 1
        case driversLicense = 2
        case ageVerificationOnly = 3
    }

    private struct DarwinConfigurationError: Error {
        let code: String
        let message: String

        static func invalidConfiguration(_ message: String) -> DarwinConfigurationError {
            DarwinConfigurationError(code: "INVALID_CONFIGURATION", message: message)
        }

        static func unsupportedDocumentType(_ message: String) -> DarwinConfigurationError {
            DarwinConfigurationError(code: "PLATFORM_UNSUPPORTED", message: message)
        }
    }
}

