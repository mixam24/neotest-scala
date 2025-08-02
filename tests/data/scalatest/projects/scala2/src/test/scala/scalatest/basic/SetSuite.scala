package neotest.scala.basic;

import org.scalatest.funsuite.AnyFunSuite;
import neotest.scala.Testable;

class SetSuite extends AnyFunSuite {

  def helperFunctionThatThrows() {
    throw new Error("Helper function that throws...");
  }

  test("An empty Set should have size 0") {
    assert(Set.empty.size == 0)
  }

  test("Invoking head on an empty Set should produce NoSuchElementException") {
    assertThrows[NoSuchElementException] {
      Set.empty.head
    }
  }
  test("This one will always fail") {
    assert(1 == 0, "Oh no...")
  }
  test("Calling a function that throw NotImplemented") {
    Testable.notImplementedError();
  }
  test("Calling a nested function that throw NotImplemented") {
    Testable.nestedFunction();
  }
  test("Calling a function that calls one in another object") {
    Testable.callFromAnotherObject();
  }
  test("Calling a helper function that throws") {
    helperFunctionThatThrows();
  }
}
