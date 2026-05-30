# typed: false
# frozen_string_literal: true

class Stackimport < Formula
  desc "HyperCard stack importer"
  homepage "https://github.com/jrepp/stackimport"
  url "https://github.com/jrepp/stackimport/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "1a5edabc41a32bc25252fe1caacfdcc64cec5307850d742e020a681ec52149a9"
  license "MIT"
  head "https://github.com/jrepp/stackimport.git", branch: "master"

  depends_on "cmake" => :build

  def install
    cmake_args = std_cmake_args
    if OS.mac?
      cmake_args.reject! { |arg| arg.start_with?("-DCMAKE_OSX_ARCHITECTURES=") }
      cmake_args << "-DCMAKE_OSX_ARCHITECTURES=#{Hardware::CPU.arch}"
    end

    system "cmake", "-S", ".", "-B", "build",
                    "-DSTACKIMPORT_BUILD_TESTS=OFF",
                    "-DSTACKIMPORT_BUILD_VENDOR_TESTS=OFF",
                    *cmake_args
    system "cmake", "--build", "build", "--target", "install"
  end

  test do
    assert_match "Missing input path", shell_output("#{bin}/stackimport 2>&1", 4)

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
