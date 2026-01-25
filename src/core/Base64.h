#pragma once

#include <string>
#include <vector>

namespace Base64 {

/**
 * Decode a Base64 encoded string into raw bytes.
 */
std::vector<unsigned char> decode(const std::string &input);

} // namespace Base64
