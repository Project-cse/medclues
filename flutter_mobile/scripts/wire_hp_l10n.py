"""Wire common hardcoded HP UI strings to AppLocalizations getters (idempotent-ish)."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib" / "screens" / "health_protection"

# Simple const Text('...') -> Text(l10n.xxx) after ensuring `final l10n = AppLocalizations.of(context)!;`
# Applied as string replacements; callers must inject l10n in build().

REPLACEMENTS = [
    ("const Text('Compare')", "Text(l10n.hpCompareAction)"),
    ("const Text('Field')", "Text(l10n.hpCompareField)"),
    ("const Text('Eligibility')", "Text(l10n.hpEligibilityTitle)"),
    ("labelText: 'Age'", "labelText: l10n.hpAge"),
    ("labelText: 'Monthly income'", "labelText: l10n.hpMonthlyIncome"),
    ("labelText: 'State / City'", "labelText: l10n.hpStateCity"),
    ("const Text('Student')", "Text(l10n.hpStudent)"),
    ("const Text('Corporate cover')", "Text(l10n.hpCorporateCover)"),
    ("const Text('Check eligibility')", "Text(l10n.hpCheckEligibility)"),
    ("const Text('Policy Analyzer')", "Text(l10n.hpPolicyAnalyzer)"),
    ("const Text('Claims')", "Text(l10n.hpClaims)"),
    ("const Text('New claim')", "Text(l10n.hpNewClaim)"),
    ("const Text('No claims yet')", "Text(l10n.hpNoClaimsYet)"),
    ("const Text('Upload documents'", "Text(l10n.hpUploadDocuments"),
    ("const Text('Submit claim')", "Text(l10n.hpSubmitClaim)"),
    ("const Text('Timeline'", "Text(l10n.hpTimeline"),
    ("const Text('Cashless hospitals')", "Text(l10n.hpCashlessHospitals)"),
    ("const Text('Call')", "Text(l10n.hpCall)"),
    ("const Text('Directions')", "Text(l10n.hpDirections)"),
    ("const Text('Book')", "Text(l10n.hpBook)"),
    ("const Text('Add family member')", "Text(l10n.hpAddFamilyMember)"),
    ("const Text('Cancel')", "Text(l10n.commonCancel)"),
    ("const Text('Add')", "Text(l10n.hpBook)".replace("hpBook", "commonSave") if False else "Text(l10n.commonSave)"),  # placeholder fixed below
]


def inject_l10n(src: str) -> str:
    """Insert `final l10n = AppLocalizations.of(context)!;` after each Widget build(…) { return Scaffold when missing."""
    marker = "final l10n = AppLocalizations.of(context)!;"
    if marker in src:
        return src
    # After `Widget build(BuildContext context) {` insert once at first build — screens have many builds
    out = []
    i = 0
    text = src
    needle = "Widget build(BuildContext context) {"
    while True:
        j = text.find(needle, i)
        if j < 0:
            out.append(text[i:])
            break
        out.append(text[i : j + len(needle)])
        # peek next non-space
        k = j + len(needle)
        snippet = text[k : k + 80]
        if marker not in snippet:
            out.append(f"\n    {marker}")
        i = k
    return "".join(out)


def main() -> None:
    mapping = [
        ("const Text('Compare')", "Text(l10n.hpCompareAction)"),
        ("const Text('Field')", "Text(l10n.hpCompareField)"),
        ("const Text('Eligibility')", "Text(l10n.hpEligibilityTitle)"),
        ("labelText: 'Age'", "labelText: l10n.hpAge"),
        ("labelText: 'Monthly income'", "labelText: l10n.hpMonthlyIncome"),
        ("labelText: 'State / City'", "labelText: l10n.hpStateCity"),
        ("const Text('Student')", "Text(l10n.hpStudent)"),
        ("const Text('Corporate cover')", "Text(l10n.hpCorporateCover)"),
        ("const Text('Check eligibility')", "Text(l10n.hpCheckEligibility)"),
        ("const Text('Policy Analyzer')", "Text(l10n.hpPolicyAnalyzer)"),
        ("const Text('Claims')", "Text(l10n.hpClaims)"),
        ("const Text('New claim')", "Text(l10n.hpNewClaim)"),
        ("const Text('No claims yet')", "Text(l10n.hpNoClaimsYet)"),
        ("const Text('Upload documents'", "Text(l10n.hpUploadDocuments"),
        ("const Text('Submit claim')", "Text(l10n.hpSubmitClaim)"),
        ("const Text('Timeline'", "Text(l10n.hpTimeline"),
        ("const Text('Cashless hospitals')", "Text(l10n.hpCashlessHospitals)"),
        ("const Text('Call')", "Text(l10n.hpCall)"),
        ("const Text('Directions')", "Text(l10n.hpDirections)"),
        ("const Text('Book')", "Text(l10n.hpBook)"),
        ("const Text('Add family member')", "Text(l10n.hpAddFamilyMember)"),
        ("const Text('Cancel')", "Text(l10n.commonCancel)"),
        ("const Text('Add')", "Text(l10n.hpAdd)"),
        ("const Text('Family dashboard')", "Text(l10n.hpFamilyDashboard)"),
        ("const Text('No family members yet')", "Text(l10n.hpNoFamilyYet)"),
        ("const Text('Add expense')", "Text(l10n.hpAddExpense)"),
        ("const Text('Save')", "Text(l10n.commonSave)"),
        ("const Text('Expense tracker')", "Text(l10n.hpExpenseTracker)"),
        ("const Text('By category'", "Text(l10n.hpByCategory"),
        ("const Text('Monthly'", "Text(l10n.hpMonthly"),
        ("const Text('Medical risk score')", "Text(l10n.hpMedicalRiskScore)"),
        ("const Text('Smoking')", "Text(l10n.hpSmoking)"),
        ("const Text('Family history')", "Text(l10n.hpFamilyHistory)"),
        ("const Text('Calculate risk')", "Text(l10n.hpCalculateRisk)"),
        ("const Text('Insurance AI Chat')", "Text(l10n.hpInsuranceAiChat)"),
        ("const Text('Protection analytics')", "Text(l10n.hpProtectionAnalytics)"),
        ("const Text('Score trend'", "Text(l10n.hpScoreTrend"),
        ("const Text('Alcohol')", "Text(l10n.hpAlcohol)"),
        ("const Text('Family members')", "Text(l10n.hpFamilyMembers)"),
        ("const Text('Why recommended'", "Text(l10n.hpWhyRecommended"),
        ("const Text('Pros'", "Text(l10n.hpPros"),
        ("const Text('Cons'", "Text(l10n.hpCons"),
        ("const Text('Emergency Card')", "Text(l10n.hpEmergencyCard)"),
        ("const Text('Digital Emergency Card'", "Text(l10n.hpDigitalEmergencyCard"),
        ("const Text('PDF share works on mobile & desktop too'", "Text(l10n.hpPdfShareHint"),
    ]
    for path in ROOT.glob("*.dart"):
        text = path.read_text(encoding="utf-8")
        original = text
        text = inject_l10n(text)
        for a, b in mapping:
            text = text.replace(a, b)
        # Special dynamic strings
        text = text.replace(
            "title: Text('Claim #${widget.claimId}')",
            "title: Text(l10n.hpClaimNumber('${widget.claimId}'))",
        )
        text = text.replace(
            "Text('Status: ${_claim?['status']}'",
            "Text(l10n.hpClaimStatus('${_claim?['status']}')",
        )
        text = text.replace(
            "Text('Expected settlement: ${_claim!['expectedSettlement']}')",
            "Text(l10n.hpExpectedSettlement('${_claim!['expectedSettlement']}'))",
        )
        text = text.replace(
            "Text('Level: ${_result!['level']} (${_result!['score']})'",
            "Text(l10n.hpRiskLevel('${_result!['level']}', '${_result!['score']}')",
        )
        text = text.replace(
            "title: Text('Score ${m['score']}')",
            "title: Text(l10n.hpScorePoint('${m['score']}'))",
        )
        text = text.replace(
            "Text(_loading ? 'Analyzing…' : 'Get top 5 plans')",
            "Text(_loading ? l10n.hpAnalyzing : l10n.hpGetTopPlans)",
        )
        text = text.replace("_tf(_occupation, 'Occupation')", "_tf(_occupation, l10n.hpOccupation)")
        text = text.replace("_tf(_income, 'Monthly income'", "_tf(_income, l10n.hpMonthlyIncome")
        text = text.replace("_tf(_city, 'City')", "_tf(_city, l10n.hpCity)")
        text = text.replace("_tf(_conditions, 'Medical conditions')", "_tf(_conditions, l10n.hpMedicalConditions)")
        text = text.replace("_tf(_budget, 'Monthly budget'", "_tf(_budget, l10n.hpMonthlyBudget")
        text = text.replace("_field(_blood, 'Blood group')", "_field(_blood, l10n.hpBloodGroup)")
        text = text.replace("_field(_policy, 'Policy number')", "_field(_policy, l10n.hpPolicyNumber)")
        text = text.replace("_field(_company, 'Insurance company')", "_field(_company, l10n.hpInsuranceCompany)")
        if text != original:
            path.write_text(text, encoding="utf-8")
            print("updated", path.name)
        else:
            print("unchanged", path.name)


if __name__ == "__main__":
    main()
