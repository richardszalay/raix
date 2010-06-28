using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using RxAs.MarbleDiagramGenerator.Parser;
using RxAs.MarbleDiagramGenerator.Domain;
using RxAs.MarbleDiagramGenerator.Renderer;

namespace RxAs.MarbleDiagramGenerator
{
    public class Program
    {
        public static void Main(string[] args)
        {
            CommandLineArguments cla = CommandLineArguments.Parse(args);

            string[] files = Directory.GetFiles(Environment.CurrentDirectory, cla.FileFilter);

            DiagramParser parser = new DiagramParser();
            DiagramRenderer renderer = new DiagramRenderer();

            foreach (string file in files)
            {
                using (Stream fileStream = File.Open(file, FileMode.Open, FileAccess.Read, FileShare.Read))
                using (StreamReader reader = new StreamReader(fileStream))
                {
                    MarbleDiagram diagram = parser.Parse(reader);

                    string outputImage = Path.ChangeExtension(file, ".png");

                    renderer.RenderImage(diagram, outputImage);
                }


            }

            

        }
    }
}
