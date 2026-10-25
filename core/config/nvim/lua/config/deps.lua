local M = {}

---Check if an executable is available on the system PATH
---@param cmd string
---@return boolean
local function has_exec(cmd)
    return vim.fn.executable(cmd) == 1
end

-- Rust: requires cargo or rustc
M.has_rust = has_exec("cargo") or has_exec("rustc")

-- Go: requires go toolchain
M.has_go = has_exec("go")

-- Java: requires javac, java, or a valid JAVA_HOME
M.has_java = has_exec("javac")
    or has_exec("java")
    or (vim.env.JAVA_HOME ~= nil and vim.env.JAVA_HOME ~= "" and vim.fn.isdirectory(vim.env.JAVA_HOME) == 1)

-- Scala: requires scala, scalac, sbt, metals, cs, or coursier
M.has_scala = has_exec("scala")
    or has_exec("scalac")
    or has_exec("sbt")
    or has_exec("metals")
    or has_exec("cs")
    or has_exec("coursier")

-- C/C++: requires clang, clang++, gcc, g++, or clangd
M.has_cpp = has_exec("clang") or has_exec("clang++") or has_exec("gcc") or has_exec("g++") or has_exec("clangd")

-- Python: requires python3 or python
M.has_python = has_exec("python3") or has_exec("python")

-- Node/JavaScript/TypeScript: requires node or npm
M.has_node = has_exec("node") or has_exec("npm")

-- Helm: requires helm CLI
M.has_helm = has_exec("helm")

return M
