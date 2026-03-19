# RCB IPL Performance & Auction Strategy Analysis

**Tools:** SQL · Excel  
**Dataset:** 4 seasons of IPL match data  
**Domain:** Sports Analytics · Business Intelligence · Strategic Planning

---

## 📌 Project Overview

This project analyzes **4 seasons of Royal Challengers Bangalore (RCB) IPL match data** using SQL and Excel to identify structural weaknesses in team performance and build a data-backed auction strategy. Every recommendation is tied directly to on-field statistics.

---

## 🎯 Business Problems Solved

| # | Strategic Question | Finding |
|---|---|---|
| 1 | Where is RCB's run dependency concentrated? | **74% of runs** from just 3 players — critical over-reliance |
| 2 | What is the bowling weakness? | **9+ death-over economy rate** — structural bowling gap |
| 3 | How does RCB perform away from home? | **10% drop in away win-rate** — venue adaptability failure |
| 4 | Where should auction budget be spent? | Middle-order depth & death bowling — **highest ROI investment areas** |

---

## 🔍 Key Findings

### 1. Batting Dependency Analysis
- Queried run contribution per player across 4 seasons
- Revealed **74% of RCB's total runs** concentrated in just 3 players
- This creates a catastrophic single point of failure — when 1 top batter fails, the entire innings collapses
- Recommendation: Invest in middle-order depth to distribute run scoring

### 2. Death-Over Bowling Crisis
- Analyzed economy rates in overs 16–20 across all matches
- Identified a **9+ death-over economy rate** — significantly above the competitive benchmark of 8.0
- This means RCB concedes 9+ runs per over in the most critical phase of the game
- Recommendation: Priority acquisition of specialist death bowlers in the auction

### 3. Home vs Away Performance
- Compared win rates across home and away fixtures
- Found a **10% drop in away match win-rate** — isolated venue adaptability as a structural weakness
- Coaching staff provided a data-backed case for fixture-specific preparation plans

### 4. Auction Strategy
- Built a position-specific auction plan backed by 4 seasons of data
- **Two highest-impact investment areas identified:**
  - Middle-order batters (positions 4–6) to reduce top-3 dependency
  - Death bowling specialists (overs 16–20) to plug the economy rate leak

---

## 🛠️ Tools & Techniques

| Tool | Usage |
|---|---|
| **SQL** | Match data querying, aggregation, player performance analysis |
| **Excel** | Data visualization, charts, auction budget modelling |
| **PowerPoint** | Final strategy presentation for stakeholders |

---

## 📁 Project Files

```
RCB---IPL-Strategy/
│
├── objective/
│   ├── RCB_Objectives.sql         # SQL queries — objective-wise analysis
│   └── RCB_Objectives.pdf         # Findings & insights (objective view)
│
├── subjective/
│   ├── RCB_Subjective.sql         # SQL queries — subjective analysis
│   └── RCB_Subjective.pdf         # Findings & insights (subjective view)
│
├── RCB_Strategy_Presentation.ppt  # Final auction strategy deck
│
└── README.md
```


## 💡 Auction Recommendations

| Priority | Position | Reason | Budget Allocation |
|---|---|---|---|
| 🔴 High | Death bowler (specialist) | Economy rate 9+ needs immediate fix | High |
| 🔴 High | Middle-order batter (4–6) | 74% run dependency on 3 players | High |
| 🟡 Medium | Utility all-rounder | Away match adaptability | Medium |

---

## 🚀 How to Run This Project

1. Clone the repo:
   ```bash
   git clone https://github.com/Sakethsiju/RCB---IPL-Strategy.git
   ```
2. Open `RCB_Objectives.sql` and `RCB_Subjective.sql` in any SQL editor
3. Load your IPL dataset as the data source
4. Run queries section by section
5. Open the `.pdf` files to view pre-computed findings
6. View `RCB_Strategy_Presentation.ppt` for the full strategy deck

---

## 📫 Connect with Me

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/enugu-saketh-reddy-21k91a6631)
[![Gmail](https://img.shields.io/badge/Gmail-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:sakethsiju63@gmail.com)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Sakethsiju)

---

*Part of my Data Analyst portfolio — using sports data to make strategic business decisions.*
