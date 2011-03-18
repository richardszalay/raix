package raix.interactive.tests.operators.filter
{
	import raix.interactive.*;
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class TakeWhileFixture
	{
		private var _source : IEnumerable = toEnumerable([
			"zero", "one", "two", "three", "four", "five"
		]);
		
		[Test]
		public function returns_values_while_predicate_returns_true() : void
		{
			AssertEx.assertArrayEquals(
				["zero", "one", "two"],
				_source.takeWhile(function(v:String):Boolean
				{
					return v.length < 5;
				}).toArray());
		}
	}
}