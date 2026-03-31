#!/usr/bin/env python3
"""
Memory Query Tool - PageIndex 记忆外挂系统
快速检索学习记录和错误记录，无需加载完整 MD 文件
"""

import json
import sys
import os
from pathlib import Path
from typing import List, Dict, Optional, Any
from datetime import datetime

# 记忆库根目录
MEMORY_DIR = Path(__file__).parent
PAGEINDEX_DIR = Path.home() / ".openclaw" / "workspace" / "PageIndex"


class MemoryIndex:
    """记忆索引管理器"""
    
    def __init__(self):
        self.index_path = MEMORY_DIR / "memory_index.json"
        self.trees: Dict[str, Dict] = {}
        self.line_cache: Dict[str, List[str]] = {}
        self._load_index()
    
    def _load_index(self):
        """加载记忆索引"""
        if self.index_path.exists():
            with open(self.index_path, 'r', encoding='utf-8') as f:
                self.index = json.load(f)
        else:
            self.index = {"documents": [], "query_patterns": {}}
    
    def _load_tree(self, doc_name: str) -> Optional[Dict]:
        """加载文档的树结构"""
        if doc_name in self.trees:
            return self.trees[doc_name]
        
        doc_info = self._get_doc_info(doc_name)
        if not doc_info or 'tree_path' not in doc_info:
            return None
        
        tree_path = Path(doc_info['tree_path'].replace("~", str(Path.home())))
        if tree_path.exists():
            with open(tree_path, 'r', encoding='utf-8') as f:
                self.trees[doc_name] = json.load(f)
                return self.trees[doc_name]
        return None
    
    def _get_doc_info(self, doc_name: str) -> Optional[Dict]:
        """获取文档信息"""
        for doc in self.index.get('documents', []):
            if doc['name'] == doc_name:
                return doc
        return None
    
    def _load_lines(self, doc_name: str) -> List[str]:
        """加载文档的行缓存"""
        if doc_name in self.line_cache:
            return self.line_cache[doc_name]
        
        doc_info = self._get_doc_info(doc_name)
        if not doc_info:
            return []
        
        doc_path = Path(doc_info['path'].replace("~", str(Path.home())))
        if doc_path.exists():
            with open(doc_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
                self.line_cache[doc_name] = lines
                return lines
        return []
    
    def _extract_keywords(self, query: str) -> List[str]:
        """从查询中提取关键词"""
        query_lower = query.lower()
        keywords = set()
        
        # 使用预定义的模式
        patterns = self.index.get('query_patterns', {})
        for pattern_name, pattern_keywords in patterns.items():
            for kw in pattern_keywords:
                if kw.lower() in query_lower:
                    keywords.add(pattern_name)
                    keywords.update(pattern_keywords)
                    break
        
        # 如果没有匹配到，使用查询词本身
        if not keywords:
            keywords.add(query)
        
        return list(keywords)
    
    def _search_in_tree(self, tree: Dict, keywords: List[str], 
                       node=None, path=None) -> List[Dict]:
        """在树结构中搜索"""
        if path is None:
            path = []
        if node is None:
            results = []
            for child in tree.get('structure', []):
                results.extend(self._search_in_tree(tree, keywords, child, path))
            return results
        
        results = []
        current_path = path + [node.get('title', 'Unknown')]
        node_title = node.get('title', '').lower()
        
        # 检查当前节点
        score = 0
        matched_keywords = []
        for kw in keywords:
            if kw.lower() in node_title:
                score += 1
                matched_keywords.append(kw)
        
        if score > 0:
            results.append({
                'node': node,
                'path': current_path,
                'score': score,
                'matched_keywords': matched_keywords,
                'doc_name': tree.get('doc_name', 'Unknown')
            })
        
        # 递归搜索子节点
        for child in node.get('nodes', []):
            results.extend(self._search_in_tree(tree, keywords, child, current_path))
        
        return results
    
    def query(self, query_text: str, top_k: int = 5) -> Dict[str, Any]:
        """
        执行记忆查询
        
        Args:
            query_text: 查询文本
            top_k: 返回结果数量
            
        Returns:
            查询结果字典
        """
        start_time = datetime.now()
        
        # 提取关键词
        keywords = self._extract_keywords(query_text)
        
        # 在所有文档中搜索
        all_results = []
        for doc in self.index.get('documents', []):
            if doc.get('type') in ['learning', 'error'] and 'tree_path' in doc:
                tree = self._load_tree(doc['name'])
                if tree:
                    results = self._search_in_tree(tree, keywords)
                    for r in results:
                        r['doc_type'] = doc['type']
                    all_results.extend(results)
        
        # 按分数排序
        all_results.sort(key=lambda x: x['score'], reverse=True)
        
        # 获取具体内容
        detailed_results = []
        for result in all_results[:top_k]:
            node = result['node']
            doc_name = result['doc_name']
            
            # 获取节点内容
            content = self._get_node_content(doc_name, node)
            
            detailed_results.append({
                'title': node.get('title', 'Unknown'),
                'node_id': node.get('node_id'),
                'line_num': node.get('line_num'),
                'path': ' → '.join(result['path']),
                'doc_name': doc_name,
                'doc_type': result['doc_type'],
                'score': result['score'],
                'content': content[:500] + '...' if len(content) > 500 else content,
                'matched_keywords': result['matched_keywords']
            })
        
        elapsed = (datetime.now() - start_time).total_seconds()
        
        return {
            'query': query_text,
            'keywords': keywords,
            'results': detailed_results,
            'total_matches': len(all_results),
            'elapsed_time': elapsed
        }
    
    def _get_node_content(self, doc_name: str, node: Dict) -> str:
        """获取节点的具体内容"""
        lines = self._load_lines(doc_name)
        if not lines:
            return "[内容无法加载]"
        
        # 找到当前节点和下一个同级节点的行号
        start_line = node.get('line_num', 1) - 1  # 转换为 0-based
        
        # 简单策略：获取当前行到下一个标题行之间的内容
        # 或者获取固定行数
        end_line = min(start_line + 30, len(lines))
        
        # 查找下一个同级标题
        current_level = self._get_header_level(lines[start_line]) if start_line < len(lines) else 0
        for i in range(start_line + 1, min(start_line + 100, len(lines))):
            level = self._get_header_level(lines[i])
            if level > 0 and level <= current_level:
                end_line = i
                break
        
        content = ''.join(lines[start_line:end_line]).strip()
        return content
    
    def _get_header_level(self, line: str) -> int:
        """获取 Markdown 标题级别"""
        stripped = line.lstrip()
        if stripped.startswith('# '):
            return 1
        elif stripped.startswith('## '):
            return 2
        elif stripped.startswith('### '):
            return 3
        elif stripped.startswith('#### '):
            return 4
        elif stripped.startswith('##### '):
            return 5
        return 0
    
    def get_stats(self) -> Dict:
        """获取记忆库统计信息"""
        total_nodes = 0
        indexed_docs = 0
        
        for doc in self.index.get('documents', []):
            if 'tree_path' in doc:
                indexed_docs += 1
                total_nodes += doc.get('node_count', 0)
        
        return {
            'total_documents': len(self.index.get('documents', [])),
            'indexed_documents': indexed_docs,
            'total_nodes': total_nodes,
            'last_updated': self.index.get('last_updated', 'Unknown')
        }


def print_results(result: Dict):
    """美观地打印查询结果"""
    print("\n" + "=" * 70)
    print(f"🔍 查询: \"{result['query']}\"")
    print(f"⏱️  耗时: {result['elapsed_time']:.3f}s")
    print(f"📊 匹配: {result['total_matches']} 个节点")
    print(f"🔑 关键词: {', '.join(result['keywords'])}")
    print("=" * 70)
    
    if not result['results']:
        print("\n❌ 未找到相关记忆")
        return
    
    for i, r in enumerate(result['results'], 1):
        icon = "📝" if r['doc_type'] == 'learning' else "🐛"
        print(f"\n{i}. {icon} {r['title']}")
        print(f"   📄 来源: {r['doc_name']} | 🔖 Node: {r['node_id']} | 📖 行: {r['line_num']}")
        print(f"   📍 路径: {r['path']}")
        print(f"   🎯 匹配: {', '.join(r['matched_keywords'])}")
        print(f"\n   💬 内容预览:")
        # 格式化内容
        content_lines = r['content'].split('\n')
        for line in content_lines[:8]:
            if line.strip():
                print(f"      {line[:80]}{'...' if len(line) > 80 else ''}")
        if len(content_lines) > 8:
            print(f"      ... ({len(content_lines) - 8} 行省略)")


def main():
    """主函数"""
    # 检查命令行参数
    if len(sys.argv) < 2:
        print("""
Usage: python memory_query.py <query> [options]

Options:
  --stats       显示记忆库统计信息
  --top-k N     返回前 N 个结果 (默认: 5)

Examples:
  python memory_query.py "飞书工具怎么配置"
  python memory_query.py "Telegram 报错" --top-k 3
  python memory_query.py --stats
        """)
        sys.exit(1)
    
    # 解析参数
    if sys.argv[1] == '--stats':
        index = MemoryIndex()
        stats = index.get_stats()
        print("\n" + "=" * 70)
        print("📊 记忆库统计")
        print("=" * 70)
        print(f"📁 总文档数: {stats['total_documents']}")
        print(f"🌲 已索引: {stats['indexed_documents']} 个文档")
        print(f"📄 总节点数: {stats['total_nodes']}")
        print(f"🔄 最后更新: {stats['last_updated']}")
        print("=" * 70)
        
        print("\n📚 文档列表:")
        for doc in index.index.get('documents', []):
            status = "✅" if 'tree_path' in doc else "⬜"
            print(f"  {status} {doc['name']}: {doc.get('description', '无描述')}")
        sys.exit(0)
    
    # 提取查询和选项
    query_text = sys.argv[1]
    top_k = 5
    
    for i, arg in enumerate(sys.argv):
        if arg == '--top-k' and i + 1 < len(sys.argv):
            top_k = int(sys.argv[i + 1])
    
    # 执行查询
    index = MemoryIndex()
    result = index.query(query_text, top_k=top_k)
    print_results(result)


if __name__ == "__main__":
    main()
