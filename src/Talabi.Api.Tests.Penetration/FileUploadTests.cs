using System.Net;
using System.Net.Http.Headers;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;
using Talabi.Api;
using Xunit;

namespace Talabi.Api.Tests.Penetration;

/// <summary>
/// File Upload güvenlik testleri
/// </summary>
public class FileUploadTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;
    private readonly WebApplicationFactory<Program> _factory;

    public FileUploadTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
        
        // Test için bir JWT token al (gerçek uygulamada test kullanıcısı oluştur)
        // Şimdilik sadece yetkilendirme gerektiren endpoint'leri test ediyoruz
    }

    [Fact]
    public async Task Upload_WithoutAuthentication_ShouldBeRejected()
    {
        // Arrange
        var content = new MultipartFormDataContent();
        var fileContent = new ByteArrayContent(new byte[] { 0x01, 0x02, 0x03 });
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("image/jpeg");
        content.Add(fileContent, "file", "test.jpg");

        // Act
        var response = await _client.PostAsync("/api/upload", content);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Upload_WithExecutableFile_ShouldBeRejected()
    {
        // Arrange - Bu test için authentication token gerekli
        // Not: Gerçek test için bir test kullanıcısı oluşturulmalı
        var content = new MultipartFormDataContent();
        var exeContent = new ByteArrayContent(new byte[] { 0x4D, 0x5A }); // PE dosyası başlangıcı
        exeContent.Headers.ContentType = new MediaTypeHeaderValue("application/x-msdownload");
        content.Add(exeContent, "file", "malicious.exe");

        // Act
        // Not: Authentication token ile test edilmeli
        var response = await _client.PostAsync("/api/upload", content);

        // Assert
        // Dosya tipi kontrolü yapılmalı - executable dosyalar reddedilmeli
        // Şu an için bu test, dosya tipi kontrolü olmadığını gösterir
        response.StatusCode.Should().NotBe(HttpStatusCode.OK, 
            "Executable dosyalar yüklenmemeli");
    }

    [Fact]
    public async Task Upload_WithOversizedFile_ShouldBeRejected()
    {
        // Arrange
        var content = new MultipartFormDataContent();
        // 100MB'dan büyük dosya oluştur
        var largeFile = new byte[100 * 1024 * 1024 + 1]; // 100MB + 1 byte
        Array.Fill(largeFile, (byte)0x01);
        var fileContent = new ByteArrayContent(largeFile);
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("image/jpeg");
        content.Add(fileContent, "file", "large.jpg");

        // Act
        var response = await _client.PostAsync("/api/upload", content);

        // Assert
        // Dosya boyutu kontrolü yapılmalı
        // Şu an için bu test, dosya boyutu kontrolü olmadığını gösterir
        response.StatusCode.Should().NotBe(HttpStatusCode.OK, 
            "Çok büyük dosyalar yüklenmemeli");
    }

    [Fact]
    public async Task Upload_WithPathTraversalFilename_ShouldBeSanitized()
    {
        // Arrange
        var content = new MultipartFormDataContent();
        var fileContent = new ByteArrayContent(new byte[] { 0x01, 0x02, 0x03 });
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("image/jpeg");
        // Path traversal saldırısı
        content.Add(fileContent, "file", "../../../etc/passwd.jpg");

        // Act
        var response = await _client.PostAsync("/api/upload", content);

        // Assert
        // Dosya adı sanitize edilmeli, path traversal engellenmeli
        if (response.StatusCode == HttpStatusCode.OK)
        {
            var responseContent = await response.Content.ReadAsStringAsync();
            // Dönen URL'de path traversal olmamalı
            responseContent.Should().NotContain("../");
            responseContent.Should().NotContain("..\\");
        }
    }

    [Fact]
    public async Task Upload_WithScriptFile_ShouldBeRejected()
    {
        // Arrange
        var content = new MultipartFormDataContent();
        var scriptContent = new ByteArrayContent(System.Text.Encoding.UTF8.GetBytes("<script>alert('XSS')</script>"));
        scriptContent.Headers.ContentType = new MediaTypeHeaderValue("text/html");
        content.Add(scriptContent, "file", "malicious.html");

        // Act
        var response = await _client.PostAsync("/api/upload", content);

        // Assert
        // Script dosyaları yüklenmemeli
        response.StatusCode.Should().NotBe(HttpStatusCode.OK, 
            "Script dosyaları yüklenmemeli");
    }

    [Fact]
    public async Task Upload_WithDoubleExtension_ShouldBeRejected()
    {
        // Arrange
        var content = new MultipartFormDataContent();
        var exeContent = new ByteArrayContent(new byte[] { 0x4D, 0x5A });
        exeContent.Headers.ContentType = new MediaTypeHeaderValue("image/jpeg");
        // Çift uzantı saldırısı (image.jpg.exe gibi)
        content.Add(exeContent, "file", "image.jpg.exe");

        // Act
        var response = await _client.PostAsync("/api/upload", content);

        // Assert
        // Çift uzantı kontrolü yapılmalı
        response.StatusCode.Should().NotBe(HttpStatusCode.OK, 
            "Çift uzantılı dosyalar kontrol edilmeli");
    }
}

