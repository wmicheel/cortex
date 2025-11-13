//
//  CortexError.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation

/// Cortex-specific error types for comprehensive error handling
enum CortexError: LocalizedError {
    // MARK: - CloudKit Errors
    case cloudKitNotAvailable
    case cloudKitAccountNotFound
    case cloudKitFetchFailed(underlying: Error)
    case cloudKitSaveFailed(underlying: Error)
    case cloudKitDeleteFailed(underlying: Error)
    case cloudKitQueryFailed(underlying: Error)
    case cloudKitRecordNotFound
    case cloudKitInvalidRecord

    // MARK: - Data Errors
    case invalidData
    case decodingFailed
    case encodingFailed

    // MARK: - General Errors
    case unknown(underlying: Error)

    // MARK: - LocalizedError Conformance
    var errorDescription: String? {
        switch self {
        case .cloudKitNotAvailable:
            return "CloudKit is not available. Please check your iCloud settings."
        case .cloudKitAccountNotFound:
            return "iCloud account not found. Please sign in to iCloud."
        case .cloudKitFetchFailed(let error):
            return "Failed to fetch data from CloudKit: \(error.localizedDescription)"
        case .cloudKitSaveFailed(let error):
            return "Failed to save data to CloudKit: \(error.localizedDescription)"
        case .cloudKitDeleteFailed(let error):
            return "Failed to delete data from CloudKit: \(error.localizedDescription)"
        case .cloudKitQueryFailed(let error):
            return "Failed to query CloudKit: \(error.localizedDescription)"
        case .cloudKitRecordNotFound:
            return "The requested record was not found."
        case .cloudKitInvalidRecord:
            return "The CloudKit record is invalid or corrupted."
        case .invalidData:
            return "The data is invalid or corrupted."
        case .decodingFailed:
            return "Failed to decode data."
        case .encodingFailed:
            return "Failed to encode data."
        case .unknown(let error):
            return "An unknown error occurred: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .cloudKitNotAvailable, .cloudKitAccountNotFound:
            return "Please ensure you are signed in to iCloud in System Settings."
        case .cloudKitFetchFailed, .cloudKitSaveFailed, .cloudKitDeleteFailed, .cloudKitQueryFailed:
            return "Please check your internet connection and try again."
        case .cloudKitRecordNotFound:
            return "The item may have been deleted. Please refresh the list."
        default:
            return "Please try again or contact support if the problem persists."
        }
    }
}
