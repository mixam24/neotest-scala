package scala.scalatest.basic

import org.scalatest.wordspec.AnyWordSpec

class WordSpec extends AnyWordSpec {

  "A Set" when {
    "empty" should {
      "have size 0" in {
        assert(Set.empty.size == 0)
      }

      "produce NoSuchElementException when head is invoked" in {
        assertThrows[NoSuchElementException] {
          Set.empty.head
        }
      }
      "and this one will always fail" in {
        assert(1 == 0)
      }
    }
  }
}
