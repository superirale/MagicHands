#ifndef ASSET_ERROR_H
#define ASSET_ERROR_H

#include <string>
#include <stdexcept>
#include <chrono>
#include <thread>
#include <sstream>

// Error code enumeration for programmatic error handling
enum class AssetErrorCode {
    // File system errors
    FileNotFound,
    FileAccessDenied,
    FileCorrupted,
    
    // Format errors
    UnsupportedFormat,
    InvalidData,
    
    // Resource errors
    OutOfMemory,
    GPUResourceExhausted,
    
    // Loading errors
    LoadTimeout,
    LoadCancelled,
    
    // Other
    Unknown
};

// Convert error code to string for display
inline const char* errorCodeToString(AssetErrorCode code) {
    switch (code) {
        case AssetErrorCode::FileNotFound: return "FileNotFound";
        case AssetErrorCode::FileAccessDenied: return "FileAccessDenied";
        case AssetErrorCode::FileCorrupted: return "FileCorrupted";
        case AssetErrorCode::UnsupportedFormat: return "UnsupportedFormat";
        case AssetErrorCode::InvalidData: return "InvalidData";
        case AssetErrorCode::OutOfMemory: return "OutOfMemory";
        case AssetErrorCode::GPUResourceExhausted: return "GPUResourceExhausted";
        case AssetErrorCode::LoadTimeout: return "LoadTimeout";
        case AssetErrorCode::LoadCancelled: return "LoadCancelled";
        case AssetErrorCode::Unknown: return "Unknown";
        default: return "Unknown";
    }
}

// Base exception class for all asset-related errors
class AssetException : public std::runtime_error {
public:
    AssetException(
        AssetErrorCode code,
        const std::string& message,
        const std::string& assetPath,
        const std::string& assetType
    ) : std::runtime_error(message),
        errorCode(code),
        assetPath(assetPath),
        assetType(assetType),
        timestamp(std::chrono::system_clock::now()),
        threadId(std::this_thread::get_id())
    {}
    
    AssetErrorCode getErrorCode() const { return errorCode; }
    const std::string& getAssetPath() const { return assetPath; }
    const std::string& getAssetType() const { return assetType; }
    std::chrono::system_clock::time_point getTimestamp() const { return timestamp; }
    std::thread::id getThreadId() const { return threadId; }
    
    // Get a detailed, formatted error message with all context
    std::string getDetailedMessage() const {
        std::ostringstream oss;
        oss << "[" << errorCodeToString(errorCode) << "] "
            << assetType << " asset error: " << what() << "\n"
            << "  Path: " << assetPath << "\n"
            << "  Thread: " << threadId;
        return oss.str();
    }
    
protected:
    AssetErrorCode errorCode;
    std::string assetPath;
    std::string assetType;
    std::chrono::system_clock::time_point timestamp;
    std::thread::id threadId;
};

// Specific exception types for different error categories

class FileNotFoundException : public AssetException {
public:
    FileNotFoundException(
        const std::string& message,
        const std::string& assetPath,
        const std::string& assetType
    ) : AssetException(AssetErrorCode::FileNotFound, message, assetPath, assetType) {}
};

class FileAccessDeniedException : public AssetException {
public:
    FileAccessDeniedException(
        const std::string& message,
        const std::string& assetPath,
        const std::string& assetType
    ) : AssetException(AssetErrorCode::FileAccessDenied, message, assetPath, assetType) {}
};

class InvalidFormatException : public AssetException {
public:
    InvalidFormatException(
        const std::string& message,
        const std::string& assetPath,
        const std::string& assetType
    ) : AssetException(AssetErrorCode::UnsupportedFormat, message, assetPath, assetType) {}
};

class InvalidDataException : public AssetException {
public:
    InvalidDataException(
        const std::string& message,
        const std::string& assetPath,
        const std::string& assetType
    ) : AssetException(AssetErrorCode::InvalidData, message, assetPath, assetType) {}
};

class ResourceExhaustedException : public AssetException {
public:
    ResourceExhaustedException(
        const std::string& message,
        const std::string& assetPath,
        const std::string& assetType,
        AssetErrorCode code = AssetErrorCode::OutOfMemory
    ) : AssetException(code, message, assetPath, assetType) {}
};

class GPUException : public AssetException {
public:
    GPUException(
        const std::string& message,
        const std::string& assetPath,
        const std::string& assetType
    ) : AssetException(AssetErrorCode::GPUResourceExhausted, message, assetPath, assetType) {}
};

#endif // ASSET_ERROR_H
