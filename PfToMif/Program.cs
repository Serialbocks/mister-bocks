using System.IO;

var bytes = File.ReadAllBytes("font.pf");
using(var streamWriter = new StreamWriter("font.mif"))
{
    foreach(var singleByte in bytes)
    {
        byte[] data = { singleByte };
        streamWriter.WriteLine(BitConverter.ToString(data));
    }
}

Console.Write("Press any key to exit...");
Console.ReadKey();