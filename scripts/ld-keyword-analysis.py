"""Legal-discuss keyword evolution analysis (L2 法律层)"""
import json
from collections import defaultdict

emails = json.load(open('data/asf/legal-full/legal-discuss-all.json'))
print(f"Total emails: {len(emails)}")

# Topic keyword groups
topics = {
    'enterprise': ['enterprise', 'corporate', 'commercial', 'vendor', 'adoption'],
    'patent': ['patent', 'patents', 'intellectual property', 'ipr'],
    'gpl-copyleft': ['gpl', 'copyleft', 'reciproc'],
    'saas-cloud': ['saas', 'saaS', 'cloud', 'docker', 'container', 'aws', 'kubernetes', 'as-a-service'],
    'al3-proposal': ['al 3.0', 'al3', 'apache license 3'],
    'trademark': ['trademark'],
    'compliance': ['compliance', 'compliant', 'spdx', 'notice file'],
    'patent-retaliation': ['retaliat', 'section 3'],
    'cla-icla': ['cla', 'icla', 'contributor license agreement'],
}

year_topics = defaultdict(lambda: defaultdict(int))
total_by_year = defaultdict(int)

for e in emails:
    y = e.get('year')
    if not y:
        continue
    text = (e.get('subject', '') + ' ' + e.get('body', '')).lower()
    total_by_year[y] += 1
    for topic, kws in topics.items():
        if any(kw in text for kw in kws):
            year_topics[y][topic] += 1

# Output table
heads = ['Year', 'total'] + list(topics.keys())
print('\t'.join(f'{h:<16}' for h in heads))
for y in sorted(year_topics.keys()):
    row = [str(y), str(total_by_year[y])]
    for t in topics:
        row.append(str(year_topics[y][t]))
    print('\t'.join(f'{v:<16}' for v in row))

# Save
out = {'years': {}, 'topics': list(topics.keys())}
for y in sorted(year_topics.keys()):
    out['years'][y] = {'total': total_by_year[y]}
    for t in topics:
        out['years'][y][t] = year_topics[y][t]
json.dump(out, open('data/asf/legal-full/keyword-evolution.json', 'w'), indent=2)
print('\nSAVED')
