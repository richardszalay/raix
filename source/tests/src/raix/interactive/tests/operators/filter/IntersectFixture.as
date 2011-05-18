package raix.interactive.tests.operators.filter
{
	import raix.interactive.toEnumerable;
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class IntersectFixture
	{
		[Test]
		public function returns_shared_list_of_hashable_objects() : void
		{
			AssertEx.assertArrayEquals(
				[3, 4],
				toEnumerable([1, 2, 3, 4])
					.intersect(toEnumerable([3, 4, 5, 6]))
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
				[leftObjects[1], leftObjects[2]],
				toEnumerable(leftObjects)
					.intersect(toEnumerable(rightObjects), function(o:Object) : int
					{
						return o.id;
					})
					.toArray());
		}
	}
}