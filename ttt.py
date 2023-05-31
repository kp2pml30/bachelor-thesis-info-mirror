import glob, os
import json
import matplotlib
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import matplotlib.lines as mlines
import numpy as np
import re
import copy

# matplotlib.rc('text', usetex=True)
#plt.rc('text.latex', unicode=True)
# plt.rcParams['text.latex.preamble']= ''.join([r'\usepackage[english,russian]{babel}'])
plt.rcParams.update({'font.size': 14})


abspath = os.path.abspath(__file__)
dname = os.path.dirname(abspath)
os.chdir(dname)

figsizes = [([12, 7], '')]

for filename in glob.iglob('artifacts/benchs/*.json'):
	if not os.path.isfile(filename):
		continue
	for figsize, suffix in figsizes:
		print(filename, suffix)
		with open(filename) as f:
			data = f.read()
		data = json.loads(data)
		labels = []
		totals = []
		times = []
		for k, v in sorted(data.items(), key=lambda x: x[0]):
			labels.append(k)
			totals.append(v['total'])
			times.append(v['times'])

		plt.figure(figsize=figsize)
		print("\tbench")
		plt.yscale('log')
		plt.ylabel('время (мс)')
		# bp = plt.boxplot(times, labels=labels, whis=(0,100), showmeans=True, meanline=True)
		def formatter(x):
			return '%.2f' % x
			y = '%.2E' % x
			match = re.search(r'(.*)E\+0*(.*)', y)
			pow = match.group(2)
			if pow == '':
				pow = 0
			res = '$' + match.group(1) + '\\cdot10^{' + pow + '}$'
			return res
		def labelPrintMap(x):
			y = '-'.join(x.split('-')[1:])
			if y == 'int':
				return 'статический\nBody'
			if y == 'int-arr':
				return 'статический\nArray<Body>'
			return 'динамические\nобъекты'
		tik_times = copy.deepcopy(times)
		le = len(max(tik_times, key=len))
		tik_times = [x + [x[0]] * (le - len(x)) for x in tik_times]
		tiks = np.median(np.array(tik_times), axis=1)
		perm = list(range(len(tiks)))
		perm.sort(key=lambda x: tiks[x])
		tiks1 = []
		tiks1_lab = []
		for xi in perm:
			x = tiks[xi]
			if len(tiks1) == 0 or np.abs(np.log(tiks1[-1]) - np.log(x)) > np.log(max(tiks) - min(tiks)) * 0.03:
				tiks1.append(x)
				tiks1_lab.append(labels[xi].split('-')[0])
			else:
				if labels[xi].split('-')[0] == 'ark':
					tiks1[-1] = x
					tiks1_lab [-1] = 'ark'
				elif tiks1_lab[-1] != 'ark':
					tiks1[-1] = (tiks1[-1] + x) / 2
		plt.yticks(tiks1, map(formatter, tiks1))
		plt.xticks(range(1, len(labels) + 1), map(labelPrintMap, labels), rotation=30)
		for i in tiks:
			plt.axhline(y=i, linestyle='dotted', alpha=0.35, color='gray')
		background_cmap = plt.get_cmap('Pastel1')
		inds = list(set([x.split('-')[0] for x in labels]))
		marker_inds = list(set(['-'.join(x.split('-')[1:]) for x in labels]))
		inds.sort()
		marker_inds.sort()
		def getColOfInd(o):
			return inds.index(o.split('-')[0])
		markers_array = [('red', '.'), ('blue', 'x'), ('green', '^')]
		def getMarkerOf(o):
			return markers_array[marker_inds.index('-'.join(o.split('-')[1:]))]
		def getColOf(o):
			return background_cmap(getColOfInd(o) / len(inds))
		legend_handles = []
		for i in inds:
			name= i
			if name == 'ark':
				name = '\\underline{ark}'
			legend_handles.append(mpatches.Patch(color = getColOf(i), label=name))
		for i in marker_inds:
			pcol, pmark = markers_array[marker_inds.index(i)]
			legend_handles.append(mlines.Line2D([], [], color=pcol, marker=pmark, linestyle='None', label=labelPrintMap('a-' + i)))
		ncol = 1
		if suffix == '-wide':
			ncol = 2
		plt.legend(handles=legend_handles, ncol=ncol)

		plt.xlim(0.5, len(labels) + 0.5)
		for i, (lab, y) in enumerate(zip(labels, times)):
			plt.axvspan(i + 0.5, i + 1.5, facecolor=getColOf(lab), alpha=0.8)
			x = np.random.normal(i + 1, 0.04, size=len(y))
			pcol, pmark = getMarkerOf(lab)
			plt.scatter(x, y, alpha=(1 - 1/(1+np.exp(-len(x) / 300))), marker=pmark, color=pcol)
		labelsSet = dict(list(zip(labels, enumerate(tiks))))
		for lf, mf in labelsSet.items():
			lt = lf + '-int'
			mt = labelsSet.get(lt)
			if mt is None:
				lt = lf + '-arr'
				mt = labelsSet.get(lt)
			if mt is None:
				continue
			beg = np.array([mf[0] + 1, mf[1]])
			end = np.array([mt[0] + 1, mt[1]])
			dir = end - beg
			real_begin = beg + dir * 0.1
			real_dir = dir * 0.8
			real_end = real_begin + real_dir
			# plt.arrow(*list(real_begin), *list(real_dir), head_width=0.1)
			plt.annotate("", xy=real_end, xytext=real_begin, arrowprops=dict(arrowstyle="->", color='black'))

		base = os.path.basename(filename).replace('.json', '')
		plt.savefig(f'hidden/{base}{suffix}.svg', format='svg', bbox_inches='tight')

		print("\ttotal")
		plt.figure(figsize=figsize)
		plt.bar(labels, totals, tick_label=labels)
		# plt.show()
		# plt.savefig(f'hidden/{base}{suffix}.total.svg', format='svg')
plt.show()
