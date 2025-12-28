return {
  cmd = {
    'clangd',
    -- '--clang-tidy',
    '--background-index',
    '--offset-encoding=utf-8',
    '--query-driver=/Users/scie/.platformio/packages/toolchain-xtensa-esp32/**',
    '--query-driver=/Users/scie/.platformio/packages/framework-arduinoststm32/**',
    -- '--query-driver=/Users/scie/.platformio/packages/**',
    -- '--query-driver=/opt/homebrew/Cellar/avr-gcc@9/9.4.0_1/bin/avr-gcc',
    -- '--query-driver=/opt/homebrew/Cellar/avr-gcc@9/9.4.0_1/bin/avr-g++'
  },
  filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda', 'proto', 'arduino' },
  root_markers = {
    '.clangd',
    '.clang-tidy',
    '.clang-format',
    'compile_commands.json',
    'compile_flags.txt',
    'configure.ac' -- AutoTools
  },
  single_file_support = true,
  capabilities = {
    textDocument = {
      completion = {
        editsNearCursor = true,
      },
    },
    offsetEncoding = { 'utf-8', 'utf-16' },
  },
}
