//
//  FirebaseCustomException.swift
//  Conversa
//
//  Created by Edgar Gomez on 2/12/18.
//  Copyright © 2018 Conversa. All rights reserved.
//

import Foundation

enum FirebaseCustomException : Error {
    /**
     Internal server error. No information available.
     */
    case kPFErrorInternalServer
    /**
     The connection to the Parse servers failed.
     */
    case kPFErrorConnectionFailed
    /**
     Object doesn't exist or has an incorrect password.
     */
    case kPFErrorObjectNotFound
    /**
     You tried to find values matching a datatype that doesn't
     support exact database matching like an array or a dictionary.
     */
    case kPFErrorInvalidQuery
    /**
     Missing or invalid classname. Classnames are case-sensitive.
     They must start with a letter and `a-zA-Z0-9_` are the only valid characters.
     */
    case kPFErrorInvalidClassName
    /**
     Missing object id.
     */
    case kPFErrorMissingObjectId
    /**
     Invalid key name. Keys are case-sensitive.
     They must start with a letter and `a-zA-Z0-9_` are the only valid characters.
     */
    case kPFErrorInvalidKeyName
    /**
     Malformed pointer. Pointers must be arrays of a classname and an object id.
     */
    case kPFErrorInvalidPointer
    /**
     Malformed json object. A json dictionary is expected.
     */
    case kPFErrorInvalidJSON
    /**
     Tried to access a feature only available internally.
     */
    case kPFErrorCommandUnavailable
    /**
     Field set to incorrect type.
     */
    case kPFErrorIncorrectType
    /**
     Invalid channel name. A channel name is either an empty string (the broadcast channel)
     or contains only `a-zA-Z0-9_` characters and starts with a letter.
     */
    case kPFErrorInvalidChannelName
    /**
     Invalid device token.
     */
    case kPFErrorInvalidDeviceToken
    /**
     Push is misconfigured. See details to find out how.
     */
    case kPFErrorPushMisconfigured
    /**
     The object is too large.
     */
    case kPFErrorObjectTooLarge
    /**
     That operation isn't allowed for clients.
     */
    case kPFErrorOperationForbidden
    /**
     The results were not found in the cache.
     */
    case kPFErrorCacheMiss
    /**
     Keys in `NSDictionary` values may not include `$` or `.`.
     */
    case kPFErrorInvalidNestedKey
    /**
     Invalid file name.
     A file name can contain only `a-zA-Z0-9_.` characters and should be between 1 and 36 characters.
     */
    case kPFErrorInvalidFileName
    /**
     Invalid ACL. An ACL with an invalid format was saved. This should not happen if you use `PFACL`.
     */
    case kPFErrorInvalidACL
    /**
     The request timed out on the server. Typically this indicates the request is too expensive.
     */
    case kPFErrorTimeout
    /**
     The email address was invalid.
     */
    case kPFErrorInvalidEmailAddress
    /**
     A unique field was given a value that is already taken.
     */
    case kPFErrorDuplicateValue
    /**
     Role's name is invalid.
     */
    case kPFErrorInvalidRoleName
    /**
     Exceeded an application quota. Upgrade to resolve.
     */
    case kPFErrorExceededQuota
    /**
     Cloud Code script had an error.
     */
    case kPFScriptError
    /**
     Cloud Code validation failed.
     */
    case kPFValidationError
    /**
     Product purchase receipt is missing.
     */
    case kPFErrorReceiptMissing
    /**
     Product purchase receipt is invalid.
     */
    case kPFErrorInvalidPurchaseReceipt
    /**
     Payment is disabled on this device.
     */
    case kPFErrorPaymentDisabled
    /**
     The product identifier is invalid.
     */
    case kPFErrorInvalidProductIdentifier
    /**
     The product is not found in the App Store.
     */
    case kPFErrorProductNotFoundInAppStore
    /**
     The Apple server response is not valid.
     */
    case kPFErrorInvalidServerResponse
    /**
     Product fails to download due to file system error.
     */
    case kPFErrorProductDownloadFileSystemFailure
    /**
     Fail to convert data to image.
     */
    case kPFErrorInvalidImageData
    /**
     Unsaved file.
     */
    case kPFErrorUnsavedFile
    /**
     Fail to delete file.
     */
    case kPFErrorFileDeleteFailure
    /**
     Application has exceeded its request limit.
     */
    case kPFErrorRequestLimitExceeded
    /**
     Invalid event name.
     */
    case kPFErrorInvalidEventName
    /**
     Username is missing or empty.
     */
    case kPFErrorUsernameMissing
    /**
     Password is missing or empty.
     */
    case kPFErrorUserPasswordMissing
    /**
     Username has already been taken.
     */
    case kPFErrorUsernameTaken
    /**
     Email has already been taken.
     */
    case kPFErrorUserEmailTaken
    /**
     The email is missing and must be specified.
     */
    case kPFErrorUserEmailMissing
    /**
     A user with the specified email was not found.
     */
    case kPFErrorUserWithEmailNotFound
    /**
     The user cannot be altered by a client without the session.
     */
    case kPFErrorUserCannotBeAlteredWithoutSession
    /**
     Users can only be created through sign up.
     */
    case kPFErrorUserCanOnlyBeCreatedThroughSignUp
    /**
     An existing Facebook account already linked to another user.
     */
    case kPFErrorFacebookAccountAlreadyLinked
    /**
     An existing account already linked to another user.
     */
    case kPFErrorAccountAlreadyLinked
    /**
     Error code indicating that the current session token is invalid.
     */
    case kPFErrorInvalidSessionToken
    case kPFErrorUserIdMismatch
    /**
     Facebook id missing from request.
     */
    case kPFErrorFacebookIdMissing
    /**
     Linked id missing from request.
     */
    case kPFErrorLinkedIdMissing
    /**
     Invalid Facebook session.
     */
    case kPFErrorFacebookInvalidSession
    /**
     Invalid linked session.
     */
    case kPFErrorInvalidLinkedSession
}

