package rx
{
	public class TaskProgress
	{
		private var _progress : Number = 0;
		
		public function TaskProgress(progress : Number)
		{
			_progress = normalizeProgress(progress);
		}
		
		public function get progress() : Number { return _progress; }
		
		private function normalizeProgress(progress : Number) : Number
		{
			if (progress < 0)
			{
				return 0;
			}
			
			if (progress > 1)
			{
				return 1;
			}
			
			return progress;
		}

	}
}