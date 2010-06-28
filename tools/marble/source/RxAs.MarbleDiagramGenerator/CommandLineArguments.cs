using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace RxAs.MarbleDiagramGenerator
{
    public class CommandLineArguments
    {
        public CommandLineArguments()
        {
        }

        public string FileFilter { get; set; }

        public string Output { get; set; }

        public static CommandLineArguments Parse(string[] args)
        {
            return new CommandLineArguments()
            {

            };
        }
    }
}
