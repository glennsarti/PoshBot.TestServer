//////////////////////////////////////////////////////////////////////
// ARGUMENTS
//////////////////////////////////////////////////////////////////////

var target = Argument<string>("target", "Default");
var configuration = Argument<string>("configuration", "Release");

//////////////////////////////////////////////////////////////////////
// PREPARATION
//////////////////////////////////////////////////////////////////////

var releaseNotes = ParseReleaseNotes("./ReleaseNotes.md");
var version = releaseNotes.Version.ToString();

var buildNumber = AppVeyor.Environment.Build.Number;
var buildSuffix = BuildSystem.IsLocalBuild ? "" : string.Concat("-build-", buildNumber);
var buildVersion = version + buildSuffix;

//////////////////////////////////////////////////////////////////////
// DIRECTORIES
//////////////////////////////////////////////////////////////////////

var sourcePath = Directory("./src");
var outputPath = sourcePath + Directory("bin");

var clientOutputPath = outputPath + Directory("ConsoleClient");
var serverOutputPath = outputPath + Directory("Server");

// var buildPath = Directory("./build/v" + buildVersion);
// var buildBinPath = buildPath + Directory("bin");
// var buildInstallerPath = buildPath + Directory("installer");
// var buildCandlePath = buildPath + Directory("installer/wixobj");
// var testResultPath = buildPath + Directory("test-results");
// var chocolateyRootPath = buildPath + Directory("chocolatey");
// var chocolateyToolsPath = chocolateyRootPath + Directory("tools");

//////////////////////////////////////////////////////////////////////
// TASKS
//////////////////////////////////////////////////////////////////////

Task("Clean")
    .Does(() =>
{
  CleanDirectories(new DirectoryPath[] { outputPath });


  // CleanDirectories(new DirectoryPath[] { buildPath, buildBinPath,
  //     buildInstallerPath, buildCandlePath, testResultPath,
  //     chocolateyRootPath, chocolateyToolsPath, outputPath });
});

Task("Update-Versions")
  .IsDependentOn("Clean")
  .Does(() =>
{
  // // Update the shared assembly info.
  // var file = "./src/SolutionInfo.cs";
  // CreateAssemblyInfo(file, new AssemblyInfoSettings {
  //     Product = "Cake",
  //     Version = version,
  //     FileVersion = version,
  //     InformationalVersion = buildVersion,
  //     Copyright = "Copyright (c) Patrik Svensson 2014"
  // });
}); 

Task("Restore-NuGet-Packages")
  .IsDependentOn("Update-Versions")
  .Does(() =>
{
  NuGetRestore("./src/PoshBotChatServer.sln");
});

Task("Build")
  .IsDependentOn("Restore-NuGet-Packages")
  .Does(() =>
{
  MSBuild("./src/PoshBotChatServer.sln", settings =>
    settings.SetConfiguration(configuration)
    .UseToolVersion(MSBuildToolVersion.NET45));
});


Task("Collate-Build-Files")
    .Does(() =>
{
  CreateDirectory(clientOutputPath);
  CreateDirectory(serverOutputPath);

  CopyFiles("./src/Client/bin/" + configuration + "/*.*", clientOutputPath);
  CopyFiles("./src/Server/bin/" + configuration + "/*.*", serverOutputPath);
});

//////////////////////////////////////////////////////////////////////
// TASK TARGETS
//////////////////////////////////////////////////////////////////////

Task("Default")
  .IsDependentOn("Build")
  .IsDependentOn("Collate-Build-Files");

// Task("AppVeyor")
//   .WithCriteria(() => AppVeyor.IsRunningOnAppVeyor)
//   .IsDependentOn("Publish-To-MyGet")
//   .IsDependentOn("Set-AppVeyor-Build-Version")
//   .IsDependentOn("Upload-AppVeyor-Artifact");

//////////////////////////////////////////////////////////////////////
// EXECUTION
//////////////////////////////////////////////////////////////////////

RunTarget(target);
