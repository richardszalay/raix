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
	public class JoinFixture
	{
		[Test]
		public function joins_sequences_based_on_key() : void
		{
			var outer : Array = [
				5, 3, 7
			];
			
			var inner : Array = [
				"bee", "giraffe", "tiger", "badger", "ox", "cat", "dog"
			];
			
			var query : IEnumerable = toEnumerable(outer).join(
				toEnumerable(inner),
				function(outer:int):int { return outer; },
				function(inner:String):int { return inner.length; },
				function(outer:int, inner:String) : String { return outer.toString() + ":" + inner; })
				
			AssertEx.assertArrayEquals(
				["5:tiger", "3:bee", "3:cat", "3:dog", "7:giraffe"],
				query.toArray());
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