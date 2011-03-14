package raix.interactive.tests.operators.mutation
{
	import flash.errors.IllegalOperationError;
	
	import raix.interactive.*;
	import raix.interactive.tests.utils.InteractiveTestUtils;
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class ToLookupFixture
	{
		[Test(expects="flash.errors.IllegalOperationError")]
		public function source_sequence_is_read_eagerly() : void
		{
			var source : IEnumerable =
				InteractiveTestUtils.throwError(new IllegalOperationError());
			
			source.toLookup(function(x:Object):Object { return x; });
		}
		
		[Test]
		public function uses_key_result_and_comparer_functions():void
		{
			var people : Array = [
				{ First : "Jon", Last : "Skeet" }, 
		        { First : "Tom", Last : "SKEET" }, // Note upper-cased name 
		        { First : "Juni", Last : "Cortez" }, 
		        { First : "Holly", Last : "Skeet" }, 
		        { First : "Abbey", Last : "Bartlet" }, 
		        { First : "Carmen", Last : "Cortez" },                 
		        { First : "Jed", Last : "Bartlet" }
			];
			
			var lookup : ILookup = toEnumerable(people).toLookup(
				function(o:Object):String { return o.Last; },
				function(o:Object):String { return o.First; },
				function(s:String):String { return s.toUpperCase(); }
			);
			
			AssertEx.assertArrayEquals(
				["Jon", "Tom", "Holly"],
				lookup.getValues("Skeet").toArray()
			);
			
			AssertEx.assertArrayEquals(
				["Juni", "Carmen"],
				lookup.getValues("Cortez").toArray()
			);
			
			AssertEx.assertArrayEquals(
				["Abbey", "Jed"],
				lookup.getValues("BARTLET").toArray()
			);
			
			AssertEx.assertArrayEquals(
				["Skeet", "Cortez", "Bartlet"],
				lookup.map(function(g:IGrouping):String { return String(g.key); })
					.toArray()
			);
		}
		
		[Test]
		public function supports_null_keys():void
		{
			var inputs : Array = [
				"one", "two", "three"
			];
			
			var lookup : ILookup = toEnumerable(inputs).toLookup(
				function(x:Object):Object { return null; });
			
			AssertEx.assertArrayEquals(
				["one", "two", "three"],
				lookup.getValues(null).toArray());
				
			AssertEx.assertArrayStrictlyEquals(
				[null],
				lookup.map(function(g:IGrouping):Object { return g.key; })
					.toArray());
		}
		
		[Test]
		public function supports_null_key_hashes():void
		{
			var inputs : Array = [
				"one", "two", "three"
			];
			
			var lookup : ILookup = toEnumerable(inputs).toLookup(
				function(x:Object):Object { return 1; },
				null,
				function(i:int):Object { return null; }
			);
			
			AssertEx.assertArrayEquals(
				["one", "two", "three"],
				lookup.getValues(5).toArray());
				
			AssertEx.assertArrayEquals(
				[1],
				lookup.map(function(g:IGrouping):Object { return g.key; })
					.toArray());
		}
	}
}