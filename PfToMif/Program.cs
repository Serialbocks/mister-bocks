using System.IO;

var bytes = File.ReadAllBytes("font.pf");
using(var streamWriter = new StreamWriter("font.mif"))
{
    streamWriter.WriteLine("WIDTH=8;");
    streamWriter.WriteLine("DEPTH=768;");
    streamWriter.WriteLine("");
    streamWriter.WriteLine("ADDRESS_RADIX=UNS;");
    streamWriter.WriteLine("DATA_RADIX=UNS;");
    streamWriter.WriteLine("");
    streamWriter.WriteLine("CONTENT BEGIN");
    int index = 0;
    foreach (var singleByte in bytes)
    {
        streamWriter.WriteLine(String.Format("    {0}    :    {1};", index, singleByte));
        index++;
    }
    streamWriter.WriteLine("END;");
}

Console.Write("Press any key to exit...");
Console.ReadKey();