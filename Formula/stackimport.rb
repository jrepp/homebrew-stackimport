# typed: false
# frozen_string_literal: true

class Stackimport < Formula
  desc "HyperCard stack importer"
  homepage "https://github.com/jrepp/stackimport"
  url "https://github.com/jrepp/stackimport/archive/refs/tags/v0.2.9.tar.gz"
  sha256 "13f343f2e69d8a98e002b3ed624f19695e81e207073c29b63c2b8737cf9545ca"
  license "MIT"
  head "https://github.com/jrepp/stackimport.git", branch: "master"

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build",
                    "-DSTACKIMPORT_BUILD_TESTS=OFF",
                    "-DSTACKIMPORT_BUILD_VENDOR_TESTS=OFF",
                    *std_cmake_args
    system "cmake", "--build", "build", "--target", "install"
  end

  test do
    assert_match "Syntax is", shell_output("#{bin}/stackimport 2>&1", 2)

    (testpath/"smoke.c").write <<~C
      #include <stackimport_c.h>
      int main(void) {
        return stackimport_api_version() == STACKIMPORT_API_VERSION ? 0 : 1;
      }
    C
    system ENV.cc, "smoke.c", "-I#{include}", "-L#{lib}",
                   "-lstackimport_c", "-Wl,-rpath,#{lib}", "-o", "smoke"
    system "./smoke"

    if OS.mac?
      assert_path_exists prefix/"Frameworks/StackImport.framework/Headers/stackimport_c.h"

      (testpath/"framework_smoke.c").write <<~C
        #include <StackImport/stackimport_c.h>
        int main(void) {
          return stackimport_api_version() == STACKIMPORT_API_VERSION ? 0 : 1;
        }
      C
      system ENV.cc, "framework_smoke.c", "-F#{prefix}/Frameworks",
                     "-framework", "StackImport", "-Wl,-rpath,#{prefix}/Frameworks",
                     "-o", "framework_smoke"
      system "./framework_smoke"
    end
  end
end
