package raix.interactive.tests.operators.filter
{
	import raix.interactive.toEnumerable;
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class DistinctFixture
	{
		[Test]
		public function returns_distinct_list_of_hashable_objects() : void
		{
			AssertEx.assertArrayEquals(
				[1, 2, 3, 4, 5],
				toEnumerable([1, 2, 3, 1, 4, 3, 2, 5])
					.distinct().toArray());
		}
		
		[Test]
		public function uses_hash_selector_for_equality() : void
		{
			var objects : Array = [
				{id:1}, {id:2}, {id:3},
				{id:1}, {id:4}, {id:3},
				{id:2}, {id:5}
			];
			
			AssertEx.assertArrayEquals(
				[objects[0], objects[1], objects[2], objects[4], objects[7]],
				toEnumerable(objects)
					.distinct(function(o:Object) : int
					{
						return o.id;
					})
					.toArray());
		}
	}
}