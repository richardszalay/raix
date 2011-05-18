package raix.interactive.tests.operators.filter
{
	import raix.interactive.toEnumerable;
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class UnionFixture
	{
		[Test]
		public function returns_distinct_list_of_hashable_objects() : void
		{
			AssertEx.assertArrayEquals(
				[1, 2, 3, 4, 5, 6, 7],
				toEnumerable([1, 2, 3, 4, 5])
					.union(toEnumerable([3, 4, 5, 6, 7]))
					.toArray());
		}
		
		[Test]
		public function uses_hash_selector_for_equality() : void
		{
			var leftObjects : Array = [
				{id:1}, {id:2}, {id:3}
			];
			
			var rightObjects : Array = [
				{id:2}, {id:3}, {id:4}
			];
			
			AssertEx.assertArrayEquals(
				[leftObjects[0], leftObjects[1], leftObjects[2], rightObjects[2]],
				toEnumerable(leftObjects)
					.union(toEnumerable(rightObjects), function(o:Object) : int
					{
						return o.id;
					})
					.toArray());
		}
	}
}