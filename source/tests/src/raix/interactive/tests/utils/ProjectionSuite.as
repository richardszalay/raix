package raix.interactive.tests.utils
{
	import org.flexunit.Assert;
	
	import raix.utils.*;
	
	[TestCase]
	public class ProjectionSuite
	{
		[Test]
		public function toString_converts_values_to_string() : void
		{
			Assert.assertStrictlyEquals("1",
				Projection.toString(1));
		}
		
		[Test]
		public function toString_leaves_null_values_as_null() : void
		{
			Assert.assertNull(Projection.toString(null));
		}
		
		[Test]
		public function toUpperCase_converts_values_to_upper_case() : void
		{
			Assert.assertEquals("HELLO",
				Projection.toUpperCase("hElLo"));
		}
		
		[Test]
		public function toUpperCase_leaves_null_values_as_null() : void
		{
			Assert.assertNull(Projection.toUpperCase(null));
		}
		
		[Test]
		public function toLowerCase_converts_values_to_lower_case() : void
		{
			Assert.assertEquals("hello",
				Projection.toLowerCase("hElLo"));
		}
		
		[Test]
		public function toLowerCase_leaves_null_values_as_null() : void
		{
			Assert.assertNull(Projection.toLowerCase(null));
		}
		
		[Test]
		public function property_retrieves_property_of_object() : void
		{
			Assert.assertEquals("correct-value",
				Projection.property("test")({test:"correct-value"}));
		}
		
		[Test]
		public function property_leaves_null_values_as_null() : void
		{
			Assert.assertNull(Projection.property("test")(null));
		}
		
		[Test(expects="ArgumentError")]
		public function property_throws_error_for_null_property_name() : void
		{
			Projection.property(null);
		}
		
		[Test(expects="ArgumentError")]
		public function property_throws_error_for_empty_property_name() : void
		{
			Projection.property("");
		}
	}
}
