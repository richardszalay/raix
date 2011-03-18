package raix.interactive.tests.operators.filter
{
	import raix.interactive.*;
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class OfTypeFixture
	{
		[Test]
		public function filters_instrinsic_types() : void
		{
			var source : Array = [
				"one", 2, "three", 4, "five"
			];
			
			AssertEx.assertArrayEquals(
				["one", "three", "five"], 
				toEnumerable(source).ofType(String).toArray());
		}
		
		[Test]
		public function filters_complex_types() : void
		{
			var source : Array = [
				new ComplexType(),
				{},
				new ComplexType(),
				"something",
				5
			];
			
			AssertEx.assertArrayEquals(
				[source[0], source[2]], 
				toEnumerable(source).ofType(ComplexType).toArray());
		}
	}
}

class ComplexType
{
	
}