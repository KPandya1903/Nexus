from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field

Category = Literal[
    "rent",
    "deposit",
    "term",
    "entry",
    "repairs",
    "termination",
    "fees",
    "utilities",
    "alterations",
    "subletting",
    "default",
    "dispute_resolution",
    "other",
]

Unit = Literal["dollars", "days", "months", "years", "percent", "other"]


class NumericValue(BaseModel):
    amount: float = Field(description="The numeric magnitude as written in the lease.")
    unit: Unit = Field(description="What the number measures.")
    context: str = Field(
        description="Brief phrase describing what this value refers to (e.g. 'monthly rent', 'late fee grace period')."
    )


class ExtractedClause(BaseModel):
    clause_id: str = Field(
        description="Stable identifier such as 'rent_amount', 'security_deposit', 'entry_rights'."
    )
    category: Category
    verbatim_text: str = Field(
        description="Exact text from the lease, copied character-for-character. No paraphrasing."
    )
    page_number: int = Field(ge=1, description="1-indexed page number where the clause appears.")
    line_reference: str = Field(
        description="Brief locator like 'Section 4.2' or 'paragraph beginning Tenant shall...'."
    )
    numeric_values: list[NumericValue] = Field(default_factory=list)
    extraction_quality: Literal["clean", "partial"] = "clean"
    notes: str | None = Field(
        default=None,
        description="Used only when extraction_quality is 'partial' to record the ambiguity.",
    )


class ExtractedLease(BaseModel):
    document_pages: int = Field(ge=1)
    clauses: list[ExtractedClause]
    extraction_warnings: list[str] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Stage 2 — Analyzer
# ---------------------------------------------------------------------------


class Statute(BaseModel):
    """One entry in the curated NJ statute reference database."""

    citation: str = Field(description="Formal citation, e.g. 'N.J.S.A. 46:8-21.1'.")
    title: str = Field(description="Short heading, e.g. 'Return of security deposit'.")
    full_text: str = Field(description="Verbatim statute text.")
    plain_summary: str = Field(description="Plain-English summary for the analyst.")
    topics: list[Category] = Field(
        default_factory=list,
        description="Clause categories this statute is relevant to.",
    )


class TenantContext(BaseModel):
    is_student: bool = False
    is_international: bool = False
    is_first_us_lease: bool = False
    notes: str | None = None


# The case Literal enforces grounding rule #3 at the type level: the model
# physically cannot emit a citation outside the hand-verified list.
ApprovedCase = Literal[
    "Marini v. Ireland, 56 N.J. 130 (1970)",
    "Reste Realty Corp. v. Cooper, 53 N.J. 444 (1969)",
    "Berzito v. Gambino, 63 N.J. 460 (1973)",
]

LegalAssessment = Literal[
    "consistent",
    "conflicts",
    "ambiguous",
    "unenforceable",
    "silent_on_protection",
    "no_law_applies",
]

RiskScore = Literal["none", "low", "moderate", "high"]

Confidence = Literal["low", "medium", "high"]


class StatuteCitation(BaseModel):
    citation: str = Field(
        description="Must match a `citation` field from the provided statute database verbatim."
    )
    relevant_quote: str = Field(
        description="Verbatim slice of the statute's text that bears on this clause."
    )
    relevance: str = Field(
        description="How this statute applies to the clause, in 1-3 sentences."
    )


class CaseCitation(BaseModel):
    case: ApprovedCase
    relevance: str = Field(
        description="How this case bears on the clause, grounded in the case's holding."
    )


class ClauseAnalysis(BaseModel):
    clause_id: str = Field(description="Echo of the clause_id from Stage 1.")
    plain_english_meaning: str = Field(
        description="Tenant-facing explanation of what the clause does. Plain English."
    )
    legal_assessment: LegalAssessment
    risk_score: RiskScore
    risk_explanation: str = Field(
        description="Tenant-facing description of the practical risk. Plain English. Never alarmist."
    )
    reasoning: str = Field(
        description="Legally precise reasoning. Quotes the verbatim clause and statute text."
    )
    statute_citations: list[StatuteCitation] = Field(
        default_factory=list,
        description="Empty when legal_assessment is 'no_law_applies'.",
    )
    case_citation: CaseCitation | None = Field(
        default=None,
        description="Optional. Only the three approved NJ cases are valid.",
    )
    confidence: Confidence
    confidence_explanation: str = Field(
        description="Why this confidence level. Required even for high confidence."
    )
    attorney_consultation_recommended: bool


# ---------------------------------------------------------------------------
# Stage 3 — Briefer (LeaseBrief)
# ---------------------------------------------------------------------------


RedFlagLabel = Literal[
    "conflicts_with_nj_law",
    "aggressive_but_legal",
    "common_but_worth_knowing",
    "recommend_attorney_review",
]


class OtherRecurringCharge(BaseModel):
    label: str = Field(description="Name of the recurring charge, e.g. 'Pet fee', 'Storage'")
    amount_annual: float = Field(description="Annual amount in dollars")


class MoneyMap(BaseModel):
    base_rent_annual: float = Field(description="Annual base rent in dollars")
    security_deposit: float = Field(description="Security deposit in dollars")
    application_fees: float = Field(default=0.0, description="Total application/screening fees")
    broker_fees: float = Field(default=0.0, description="Broker or finder's fees")
    last_month_required: bool = Field(description="Whether last month's rent is required up front")
    last_month_amount: float | None = Field(
        default=None, description="Last month's rent amount if required"
    )
    late_fee_structure: str = Field(
        description="Plain-English description of when and how much late fees apply"
    )
    utility_responsibilities: str = Field(
        description="Plain-English description of utility allocation"
    )
    parking: float | None = Field(
        default=None, description="Annual parking cost if separately charged"
    )
    amenity_fees: float | None = Field(
        default=None, description="Annual amenity fees if separately charged"
    )
    other_recurring: list[OtherRecurringCharge] = Field(default_factory=list)
    estimated_total_annual: float = Field(description="Best-estimate total annual cost to tenant")
    notes: str = Field(description="One sentence calling out anything unusual about cost structure")


class RedFlag(BaseModel):
    clause_id: str
    headline: str = Field(description="5-10 word active-voice summary")
    verbatim_text: str = Field(description="Exact lease text, never paraphrased")
    statute_citations: list[StatuteCitation] = Field(
        default_factory=list,
        description="Full StatuteCitation objects from Stage 2, never bare strings",
    )
    explanation: str = Field(description="2-3 plain-English sentences")
    label: RedFlagLabel
    risk: Literal["moderate", "high"]


class NegotiationOpening(BaseModel):
    clause_id: str
    headline: str
    draft_message: str = Field(
        description="2-4 sentence professional message tenant can send landlord"
    )
    counter_position: str = Field(description="One-sentence statement of what tenant is asking for")


class Referral(BaseModel):
    name: str
    url: str


class ClosingNotes(BaseModel):
    not_legal_advice_disclaimer: str
    when_to_consult_attorney: str
    referrals: list[Referral]


class LeaseBrief(BaseModel):
    consent_clarity_score: int = Field(ge=1, le=100)
    score_meaning: str
    plain_english_summary: list[str] = Field(min_length=5, max_length=5)
    money_map: MoneyMap
    red_flags: list[RedFlag] = Field(default_factory=list)
    negotiation_openings: list[NegotiationOpening] = Field(default_factory=list, max_length=3)
    closing_notes: ClosingNotes
    consenterra_attribution: str = (
        "Brief generated using the ConsenTerra framework for consent clarity."
    )
    mocked_in_demo: bool = False
