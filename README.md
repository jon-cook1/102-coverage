# COSC 102 Automated Test Harness

This repository ships two scripts that drop a fully configured Maven test harness **next to** your existing lab.  
The harness bundles **JUnit 5** for unit tests and **JaCoCo** for line‑coverage reports—no manual Maven installation needed.

---

## Prerequisites

* **Java 17 or later** installed  
* Git command‑line tools

*(The repo already contains the Maven wrapper, so Maven itself does **not** have to be installed.)*

---

## Setup (one‑time)

1. **Open a terminal in the folder that *contains* your lab directory**  
   *(do **not** `cd` into the lab itself).*

2. **Clone this harness repository:**

   ~~~bash
   git clone https://github.com/jon-cook1/102-coverage.git
   ~~~

3. **Run the setup script, pointing to your lab folder**  
   (replace `MyLab` with your actual lab name):

   ~~~bash
   cd 102-coverage
   ./setup_tests.sh  ../MyLab
   ~~~

   *What happens:*

   * Detects every folder inside `MyLab` that holds `.java` files  
   * Generates `pom.xml` with those folders as sources  
   * Adds JUnit 5 and JaCoCo plug‑ins  
   * Compiles the lab and creates an initial coverage report

---

## Daily workflow

From inside **`102-coverage/`** just run:

~~~bash
./run_tests.sh
~~~

* The script silently checks for any new `.java` files you added to your lab and refreshes its config if needed.  
* Compiles your lab, runs all tests, and opens the updated coverage report (`target/site/jacoco/index.html`) in your browser.

---

## Writing tests

* Add new test classes under `102-coverage/src/test/java/`
* Each test method needs the `@Test` annotation.
* Use JUnit assertions (`assertEquals`, `assertTrue`, etc.).

Example:

```java
import static org.junit.jupiter.api.Assertions.*;
import org.junit.jupiter.api.Test;

class ArrayUtilsTest {
    @Test void meanOfFiveNumbers() {
        int[] nums = {1, 2, 3, 4, 5};
        assertEquals(3.0, utils.ArrayUtils.mean(nums), 1e-9);
    }
}
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `./setup_tests.sh: permission denied` | Make the scripts executable: `chmod +x setup_tests.sh run_tests.sh mvnw` |
| `No lab has been set up yet` when running `run_tests.sh` | First execute `./setup_tests.sh  ../MyLab` (replace **MyLab** with your lab folder). |
| New `.java` files aren’t being compiled | `./run_tests.sh` auto‑refreshes, but if you moved code into a **new folder** rerun `./setup_tests.sh  ../MyLab` once to update the source list. |
| Coverage report doesn’t open automatically | Open `target/site/jacoco/index.html` manually in your browser. |
| Tests pass locally but fail here | Ensure test classes live in `102-coverage/src/test/java` **and** their names end with `Test`. |




