import '../guide_data.dart';

final List<GuideArticle> kGintongTaonGuides = [
  GuideArticle(
    slug: 'senior-citizen-benefits',
    title: 'Senior Citizen Benefits Complete Guide',
    readMinutes: 5,
    category: 'retirement',
    toolLinks: [],
    sections: [
      GuideSection(
        title: 'Who qualifies',
        content:
            'Filipino citizens aged 60 and above are considered senior citizens under the law. To access benefits, you need a Senior Citizen ID issued by the Office for Senior Citizens Affairs (OSCA) in your city or municipality. Registration is free.',
      ),
      GuideSection(
        title: 'Mandatory discounts',
        content:
            'Senior citizens are entitled to a 20% discount and VAT exemption on:',
        items: [
          'Medicines, vitamins, and medical supplies in all drugstores',
          'Medical and dental services, diagnostic fees, and professional fees',
          'Public transportation (bus, jeepney, MRT, LRT, PNR)',
          'Hotels, restaurants, and recreation centers',
          'Funeral and burial services',
          'Admission to theaters, concert halls, and amusement parks',
        ],
        callout:
            'These discounts are mandatory under Republic Act 9994 (Expanded Senior Citizens Act of 2010). Establishments that refuse to honor them can be fined P50,000 for first offense.',
        calloutType: 'ph-law',
      ),
      GuideSection(
        title: 'Social pension for indigent seniors',
        content:
            'The DSWD provides a monthly social pension of P1,000 to indigent senior citizens \u2014 those without regular income, pension, or permanent source of financial support. Apply through your barangay or city social welfare office.',
      ),
      GuideSection(
        title: 'SSS and GSIS pension claims',
        content:
            'If you\u2019ve completed the required contributions, file your retirement claim:',
        items: [
          'SSS: Optional retirement at age 60 (must stop working), mandatory at 65. Minimum 120 monthly contributions required.',
          'GSIS: For government employees. File through your agency HR or the nearest GSIS branch.',
          'Keep your records: Contribution history, employment records, and valid IDs ready for the claims process.',
        ],
      ),
    ],
  ),
  GuideArticle(
    slug: 'healthcare-retirement',
    title: 'Healthcare Management in Retirement',
    readMinutes: 4,
    category: 'health',
    toolLinks: ['insurance'],
    sections: [
      GuideSection(
        title: 'Healthcare costs in retirement',
        content:
            'Healthcare is typically the largest expense for Filipino retirees. Out-of-pocket health spending accounts for 42.7% of total healthcare costs in the Philippines. Without proper coverage, a single hospitalization can wipe out years of savings.',
      ),
      GuideSection(
        title: 'Maximizing PhilHealth as a retiree',
        content:
            'As a retiree, you can maintain PhilHealth coverage:',
        items: [
          'Lifetime member: If you\u2019ve contributed for 120 months, you qualify for lifetime coverage',
          'Senior citizen PhilHealth: Automatic coverage under the Universal Health Care Act',
          'Konsulta package: Free outpatient primary care at accredited health centers',
          'New 2025 benefits: Expanded coverage for heart disease, kidney transplant, dental, and emergency care',
        ],
      ),
      GuideSection(
        title: 'Building a healthcare fund',
        content:
            'Beyond PhilHealth, set aside dedicated funds for medical expenses not covered by insurance. A healthcare fund of P200,000\u2013P500,000 provides a buffer for emergencies, medications, and procedures that PhilHealth doesn\u2019t fully cover.',
        callout:
            'Keep your healthcare fund in a high-yield savings account (not invested). You need it liquid and accessible for emergencies.',
        calloutType: 'tip',
      ),
    ],
  ),
  GuideArticle(
    slug: 'passing-wealth',
    title: 'Passing Wealth to the Next Generation',
    readMinutes: 4,
    category: 'retirement',
    toolLinks: [],
    sections: [
      GuideSection(
        title: 'Planning the transfer',
        content:
            'Wealth transfer in the Philippines is governed by the Civil Code\u2019s rules on succession. Whether you have P100,000 or P10,000,000, how you transfer it matters \u2014 both for tax efficiency and family harmony.',
      ),
      GuideSection(
        title: 'Strategies for smooth transfer',
        content: 'Consider these approaches:',
        items: [
          'Write a will: Even a holographic (handwritten) will prevents intestate succession disputes',
          'Update beneficiaries: SSS, Pag-IBIG, bank accounts, insurance \u2014 review annually',
          'Consider living donations: You can donate up to P250,000/year tax-free to each child',
          'Insurance as estate tool: A life insurance payout goes directly to beneficiaries, bypassing estate settlement',
          'Organize documentation: Land titles, vehicle registration, bank records \u2014 make them easily accessible',
        ],
      ),
      GuideSection(
        title: 'Avoiding common pitfalls',
        content:
            'These mistakes cause the most pain for Filipino families:',
        items: [
          'No will: Assets get divided by intestate law, which may not match your wishes',
          'Verbal promises: \u2018I told my anak they\u2019d get the house\u2019 has no legal weight without documentation',
          'Co-mingled property: Assets with unclear ownership create disputes. Keep titles and records clean',
          'Ignoring estate tax: The 6% estate tax must be paid before assets can be transferred. Plan for it',
        ],
        callout:
            'Under Philippine law, legitimate children, the surviving spouse, and (in some cases) parents are compulsory heirs who cannot be disinherited from their legal share (legitime).',
        calloutType: 'ph-law',
      ),
    ],
  ),
];
