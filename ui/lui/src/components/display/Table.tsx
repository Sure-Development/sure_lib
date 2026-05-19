import type { LuiNode } from '../../schemas/node'
import { nodeClassName, nodePartClassName, nodePartStyle, nodeStyle } from '../shared/nodeProps'

type TableProps = {
  node: LuiNode
}

type Column = {
  key: string
  label: string
}

function normalizeColumns(value: unknown): Column[] {
  if (!Array.isArray(value)) {
    return []
  }

  return value.map((column) => {
    if (typeof column === 'object' && column !== null) {
      const record = column as Record<string, unknown>
      const key = String(record.key ?? record.value ?? record.label ?? '')
      return {
        key,
        label: String(record.label ?? key),
      }
    }

    const key = String(column)
    return {
      key,
      label: key,
    }
  })
}

function normalizeRows(value: unknown): Array<Record<string, unknown>> {
  return Array.isArray(value) ? (value.filter((item) => typeof item === 'object' && item !== null) as Array<Record<string, unknown>>) : []
}

export function Table({ node }: TableProps) {
  const columns = normalizeColumns(node.props.columns)
  const rows = normalizeRows(node.props.rows)

  return (
    <div className={nodeClassName(node.props, 'w-full overflow-auto rounded-md border border-lui-line')} style={nodeStyle(node.props)}>
      <table className={nodePartClassName(node.props, 'tableClassName', 'w-full caption-bottom text-sm')} style={nodePartStyle(node.props, 'tableClassName')}>
        {node.props.caption !== undefined && (
          <caption className={nodePartClassName(node.props, 'captionClassName', 'mt-4 text-sm text-lui-muted')} style={nodePartStyle(node.props, 'captionClassName')}>
            {String(node.props.caption)}
          </caption>
        )}
        <thead className={nodePartClassName(node.props, ['headerClassName', 'theadClassName'], 'border-b border-lui-line')} style={nodePartStyle(node.props, ['headerClassName', 'theadClassName'])}>
          <tr className={nodePartClassName(node.props, 'headerRowClassName', '')} style={nodePartStyle(node.props, 'headerRowClassName')}>
            {columns.map((column) => (
              <th key={column.key} className={nodePartClassName(node.props, ['headClassName', 'headerCellClassName', 'thClassName'], 'h-10 px-2 text-left align-middle font-medium text-lui-muted')} style={nodePartStyle(node.props, ['headClassName', 'headerCellClassName', 'thClassName'])}>
                {column.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className={nodePartClassName(node.props, ['bodyClassName', 'tbodyClassName'], '')} style={nodePartStyle(node.props, ['bodyClassName', 'tbodyClassName'])}>
          {rows.map((row, rowIndex) => (
            <tr key={String(row.id ?? row.key ?? rowIndex)} className={nodePartClassName(node.props, 'rowClassName', 'border-b border-lui-line last:border-0')} style={nodePartStyle(node.props, 'rowClassName')}>
              {columns.map((column) => (
                <td key={column.key} className={nodePartClassName(node.props, ['cellClassName', 'tdClassName'], 'p-2 align-middle text-lui-ink')} style={nodePartStyle(node.props, ['cellClassName', 'tdClassName'])}>
                  {String(row[column.key] ?? '')}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
