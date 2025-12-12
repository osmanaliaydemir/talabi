using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace Getir.MerchantPortal.Models;

public class MerchantDocumentsViewModel
{
    public Guid MerchantId { get; set; }
    public PagedResult<MerchantDocumentResponse> Documents { get; set; } = new();
    public MerchantDocumentProgressResponse? Progress { get; set; }
    public IReadOnlyList<DocumentTypeResponse> RequiredTypes { get; set; } = Array.Empty<DocumentTypeResponse>();
    public MerchantDocumentStatisticsResponse? Statistics { get; set; }
    public string? SelectedStatus { get; set; }
    public string? SelectedDocumentType { get; set; }
    public bool IsAdmin { get; set; }
}

public class UploadMerchantDocumentViewModel
{
    public UploadMerchantDocumentRequest Request { get; set; } = new();
    public IReadOnlyList<DocumentTypeResponse> AvailableTypes { get; set; } = Array.Empty<DocumentTypeResponse>();
}

public class MerchantDocumentDetailViewModel
{
    public MerchantDocumentResponse Document { get; set; } = default!;
    public bool IsAdmin { get; set; }
}

public class DocumentVerificationInput
{
    [Required]
    public bool IsApproved { get; set; }

    public string? VerificationNotes { get; set; }

    public string? RejectionReason { get; set; }
}

public class PendingDocumentsViewModel
{
    public PagedResult<MerchantDocumentResponse> Documents { get; set; } = new();
    public bool IsAdmin { get; set; }
}

public class BulkVerifyDocumentsInput
{
    [Required]
    [MinLength(1, ErrorMessage = "En az bir belge seçmelisiniz.")]
    public List<Guid> DocumentIds { get; set; } = new();

    [Required]
    public bool IsApproved { get; set; }

    public string? VerificationNotes { get; set; }
}

