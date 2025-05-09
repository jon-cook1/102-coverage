#!/usr/bin/env bash
# ------------------------------------------------------------------
# setup_tests.sh  <path-to-lab-directory>
#
# • Creates or refreshes a Maven test harness (JUnit 5 + JaCoCo)
#   that compiles everything in the specified lab directory.
# • Works on default macOS / BSD tools (no Bash‑4 mapfile, no grep -P).
# • Safe to rerun: detects lab changes, rewrites pom.xml as needed.
# ------------------------------------------------------------------

set -euo pipefail

# ---------- 0. validate input -------------------------------------
if [ $# -lt 1 ]; then
  echo "Usage: $0 <path-to-lab-directory>" >&2
  exit 1
fi

LAB_DIR="$(cd "$1" && pwd)"
if [ ! -d "$LAB_DIR" ]; then
  echo "Lab directory not found: $LAB_DIR" >&2
  exit 1
fi

HARNESS_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$HARNESS_DIR"

LAB_PATH_FILE=".lab_path"

# ---------- 1. detect lab switch ----------------------------------
if [ -f "$LAB_PATH_FILE" ]; then
  PREV_LAB="$(cat "$LAB_PATH_FILE")"
else
  PREV_LAB=""
fi

if [ "$PREV_LAB" != "$LAB_DIR" ]; then
  echo "↻  Setting up harness for NEW lab: $LAB_DIR"
  # remove old build artefacts; keep tests
  rm -rf target pom.xml
fi
echo "$LAB_DIR" > "$LAB_PATH_FILE"

# ---------- 2. ensure basic skeleton ------------------------------
mkdir -p src/test/java

# include Maven wrapper if repo didn't already ship it
if [ ! -x mvnw ]; then
  echo "Downloading Maven wrapper…"
  WRAPPER_URL="https://repo.maven.apache.org/maven2/org/apache/maven/wrapper/maven-wrapper/3.2.0/maven-wrapper-3.2.0.zip"
  curl -fsSL "$WRAPPER_URL" -o wrapper.zip
  unzip -q wrapper.zip
  rm wrapper.zip
  chmod +x mvnw
fi

# ---------- 3. list all source folders inside the lab -------------
SRC_DIRS=$(find "$LAB_DIR" -type f -name '*.java' -exec dirname {} \; | sort -u)
if [ -z "$SRC_DIRS" ]; then
  echo "No .java files found in $LAB_DIR" >&2
  exit 1
fi
echo "[✓] Found $(printf '%s\n' $SRC_DIRS | wc -l) Java source folders"

# build XML <sources> block
SRC_XML=""
for d in $SRC_DIRS; do
  SRC_XML="$SRC_XML                <source>$d</source>\n"
done

# ---------- 4. (re)generate pom.xml -------------------------------
cat > pom.xml <<EOF
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>edu.cosc102</groupId>
  <artifactId>lab-tests</artifactId>
  <version>1.0.0</version>

  <properties>
    <maven.compiler.source>17</maven.compiler.source>
    <maven.compiler.target>17</maven.compiler.target>
  </properties>

  <build>
    <plugins>

      <!-- import external lab source folders -->
      <plugin>
        <groupId>org.codehaus.mojo</groupId>
        <artifactId>build-helper-maven-plugin</artifactId>
        <version>3.5.0</version>
        <executions>
          <execution>
            <id>add-src</id><phase>generate-sources</phase>
            <goals><goal>add-source</goal></goals>
            <configuration>
              <sources>
$(printf "%b" "$SRC_XML")              </sources>
            </configuration>
          </execution>
        </executions>
      </plugin>

      <!-- run JUnit 5 -->
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>3.2.5</version>
        <configuration><useModulePath>false</useModulePath></configuration>
      </plugin>

      <!-- collect coverage -->
      <plugin>
        <groupId>org.jacoco</groupId>
        <artifactId>jacoco-maven-plugin</artifactId>
        <version>0.8.13</version>
        <executions>
          <execution><goals><goal>prepare-agent</goal></goals></execution>
          <execution>
            <id>report</id><phase>test</phase><goals><goal>report</goal></goals>
          </execution>
        </executions>
      </plugin>

    </plugins>
  </build>

  <dependencies>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter</artifactId>
      <version>5.12.2</version>
      <scope>test</scope>
    </dependency>
  </dependencies>
</project>
EOF
echo "[✓] pom.xml written"

# ---------- 5. add placeholder test once --------------------------
if [ ! -f src/test/java/SampleTest.java ]; then
  cat > src/test/java/SampleTest.java <<'JAVA'
import static org.junit.jupiter.api.Assertions.*;
import org.junit.jupiter.api.Test;

class SampleTest {
    @Test void demo() { assertTrue(true); }
}
JAVA
  echo "[✓] Added SampleTest.java"
fi

# ---------- 6. run first build + coverage -------------------------
./mvnw -q clean test
echo "[✓] Harness ready (coverage report generated)"
echo "   open $(pwd)/target/site/jacoco/index.html"
