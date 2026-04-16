#include "utils.h"

#include <flutter_windows.h>
#include <io.h>
#include <stdio.h>
#include <windows.h>

#include <iostream>

namespace {

bool SetRegistryDefaultValue(HKEY key, const std::wstring& value) {
  const auto* bytes = reinterpret_cast<const BYTE*>(value.c_str());
  const DWORD size = static_cast<DWORD>((value.size() + 1) * sizeof(wchar_t));
  return RegSetValueExW(key, nullptr, 0, REG_SZ, bytes, size) == ERROR_SUCCESS;
}

bool SetRegistryNamedValue(HKEY key,
                           const wchar_t* name,
                           const std::wstring& value) {
  const auto* bytes = reinterpret_cast<const BYTE*>(value.c_str());
  const DWORD size = static_cast<DWORD>((value.size() + 1) * sizeof(wchar_t));
  return RegSetValueExW(key, name, 0, REG_SZ, bytes, size) == ERROR_SUCCESS;
}

bool CreateRegistryKey(HKEY root,
                       const std::wstring& path,
                       HKEY* created_key) {
  DWORD disposition = 0;
  return RegCreateKeyExW(root, path.c_str(), 0, nullptr, 0,
                         KEY_WRITE, nullptr, created_key,
                         &disposition) == ERROR_SUCCESS;
}

}  // namespace

void CreateAndAttachConsole() {
  if (::AllocConsole()) {
    FILE *unused;
    if (freopen_s(&unused, "CONOUT$", "w", stdout)) {
      _dup2(_fileno(stdout), 1);
    }
    if (freopen_s(&unused, "CONOUT$", "w", stderr)) {
      _dup2(_fileno(stdout), 2);
    }
    std::ios::sync_with_stdio();
    FlutterDesktopResyncOutputStreams();
  }
}

std::vector<std::string> GetCommandLineArguments() {
  // Convert the UTF-16 command line arguments to UTF-8 for the Engine to use.
  int argc;
  wchar_t** argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv == nullptr) {
    return std::vector<std::string>();
  }

  std::vector<std::string> command_line_arguments;

  // Skip the first argument as it's the binary name.
  for (int i = 1; i < argc; i++) {
    command_line_arguments.push_back(Utf8FromUtf16(argv[i]));
  }

  ::LocalFree(argv);

  return command_line_arguments;
}

std::string Utf8FromUtf16(const wchar_t* utf16_string) {
  if (utf16_string == nullptr) {
    return std::string();
  }
  unsigned int target_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      -1, nullptr, 0, nullptr, nullptr)
    -1; // remove the trailing null character
  int input_length = (int)wcslen(utf16_string);
  std::string utf8_string;
  if (target_length == 0 || target_length > utf8_string.max_size()) {
    return utf8_string;
  }
  utf8_string.resize(target_length);
  int converted_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      input_length, utf8_string.data(), target_length, nullptr, nullptr);
  if (converted_length == 0) {
    return std::string();
  }
  return utf8_string;
}

bool RegisterUrlSchemeForCurrentUser(const wchar_t* scheme,
                                     const wchar_t* executable_path) {
  if (scheme == nullptr || executable_path == nullptr) {
    return false;
  }

  const std::wstring scheme_name(scheme);
  const std::wstring executable(executable_path);
  if (scheme_name.empty() || executable.empty()) {
    return false;
  }

  const std::wstring base_key_path =
      L"Software\\Classes\\" + scheme_name;
  const std::wstring command = L'"' + executable + L'"' + L" \"%1\"";

  HKEY base_key = nullptr;
  if (!CreateRegistryKey(HKEY_CURRENT_USER, base_key_path, &base_key)) {
    return false;
  }

  bool success = SetRegistryDefaultValue(
                     base_key, L"URL:" + scheme_name + L" Protocol") &&
                 SetRegistryNamedValue(base_key, L"URL Protocol", L"");
  RegCloseKey(base_key);

  HKEY icon_key = nullptr;
  if (success &&
      CreateRegistryKey(HKEY_CURRENT_USER,
                        base_key_path + L"\\DefaultIcon", &icon_key)) {
    success = SetRegistryDefaultValue(icon_key, executable + L",0");
    RegCloseKey(icon_key);
  } else if (success) {
    success = false;
  }

  HKEY command_key = nullptr;
  if (success &&
      CreateRegistryKey(HKEY_CURRENT_USER,
                        base_key_path + L"\\shell\\open\\command",
                        &command_key)) {
    success = SetRegistryDefaultValue(command_key, command);
    RegCloseKey(command_key);
  } else if (success) {
    success = false;
  }

  return success;
}
