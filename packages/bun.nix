{ bun, fetchurl }:

bun.overrideAttrs (_: {
  version = "1.3.14";

  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v1.3.14/bun-linux-x64.zip";
    hash = "sha256-lR7iruhV8IWVruxiJSJqKY0/6oOj3NZGXAnLzN9+hI8=";
  };
})
