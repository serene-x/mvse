-- Reference URLs for ingredient and claim records.

update public.ingredients set sources = '[
  {"title":"Mechanistic Basis and Clinical Evidence for Nicotinamide in Skin Aging and Pigmentation","url":"https://pmc.ncbi.nlm.nih.gov/articles/PMC8389214/","publisher":"Antioxidants (PMC)"},
  {"title":"Nicotinic acid/niacinamide and the skin","url":"https://pubmed.ncbi.nlm.nih.gov/17147561/","publisher":"J Cosmet Dermatol (PubMed)"}
]'::jsonb
where inci_name = 'Niacinamide';

update public.ingredients set sources = '[
  {"title":"Topical tretinoin for treating photoaging: a systematic review of randomized controlled trials","url":"https://pmc.ncbi.nlm.nih.gov/articles/PMC9112391/","publisher":"J Cosmet Dermatol (PMC)"}
]'::jsonb
where inci_name = 'Retinol';

update public.ingredients set sources = '[
  {"title":"Ferulic acid stabilizes a solution of vitamins C and E and doubles its photoprotection of skin (Lin et al., 2005)","url":"https://pubmed.ncbi.nlm.nih.gov/16185284/","publisher":"J Invest Dermatol (PubMed)"}
]'::jsonb
where inci_name in ('Ascorbic Acid', 'Ferulic Acid', 'Tocopherol');

-- No source is assigned to the niacinamide/vitamin C claim.
