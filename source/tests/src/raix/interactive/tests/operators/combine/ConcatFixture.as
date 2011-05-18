package raix.interactive.tests.operators.combine
{
	import flash.errors.IllegalOperationError;
	
	import org.flexunit.Assert;
	
	import raix.interactive.Enumerable;
	import raix.interactive.IEnumerable;
	import raix.interactive.IEnumerator;
	import raix.interactive.toEnumerable;
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class ConcatFixture
	{
		[Test]
		public function enumerates_second_sequence_after_first() : void
		{
			AssertEx.assertArrayEquals(
				[1, 2, 3, 4],
				toEnumerable([1, 2])
					.concat(toEnumerable([3, 4]))
					.toArray());
		}
		
		[Test(expects="flash.errors.IllegalOperationError")]
		public function does_not_enumerate_second_sequence_until_first_has_completed() : void
		{
			var throwEnumerable : IEnumerable = Enumerable.generate(null,
				function():Boolean { throw new IllegalOperationError(); },
				function():void { },
				function(v:Object):Object { return v; });
			
			var enumerable : IEnumerable = Enumerable.value(1)
				.concat(throwEnumerable);
			
			var enumerator : IEnumerator = enumerable.getEnumerator();
			
			try
			{
				enumerator.moveNext();
			}
			catch(err : IllegalOperationError)
			{
				Assert.fail("Error thrown too early");
			}
			
			enumerator.moveNext();
		}
	}
}