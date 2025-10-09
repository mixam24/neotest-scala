package neotest.basic;

import munit.FunSuite;
import neotest.scala.Testable;
import scala.concurrent.Future
import scala.util.Random

case class Rerun(count: Int) extends munit.Tag("Rerun")
class BasicSuite extends FunSuite {
  implicit val ec: scala.concurrent.ExecutionContext =
    scala.concurrent.ExecutionContext.global
  override def munitTestTransforms = super.munitTestTransforms ++ List(
    new TestTransform(
      "Rerun",
      { test =>
        val rerunCount = test.tags
          .collectFirst { case Rerun(n) => n }
          .getOrElse(1)
        if (rerunCount == 1) test
        else {
          test.withBody(() => {
            Future.sequence(1.to(rerunCount).map(_ => test.body()).toList)
          })
        }
      }
    )
  )

  def helperFunctionThatThrows() {
    throw new Error("Helper function that throws...");
  }

  test("An empty Set should have size 0") {
    assert(Set.empty.size == 0)
  }

  test(
    "Invoking head on an empty Set should produce NoSuchElementException".fail
  ) {
    Set.empty.head
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
  test("Not ready yet test".pending("requirements")) {
    assertEquals(1, 1);
  }
  test("Some test to re-run".tag(Rerun(2))) {
    assertEquals(1, 1);
  }
  test("Some flaky test".flaky) {
    assertEquals(Random.between(0, 2), 1);
  }
}
