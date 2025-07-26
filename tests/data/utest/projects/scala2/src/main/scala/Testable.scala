package neotest.scala;

object Testable {
  def notImplementedError() {
    throw new NotImplementedError("Not implemented!");
  }

  def nestedFunction() {
    assert(1 == 1);
    notImplementedError();
  }

  def callFromAnotherObject() {
    Callable.functionThatThrowsError();
  }
}
