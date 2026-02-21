import { useState } from 'react';
import { HiOutlineSearch, HiOutlineChevronLeft, HiOutlineChevronRight } from 'react-icons/hi';

export default function DataTable({
  columns,
  data,
  pagination,
  onPageChange,
  onSearch,
  searchPlaceholder = 'Buscar...',
  actions,
  emptyMessage = 'No hay datos para mostrar',
}) {
  const [searchTerm, setSearchTerm] = useState('');

  const handleSearch = (e) => {
    e.preventDefault();
    onSearch?.(searchTerm);
  };

  return (
    <div className="space-y-4">
      {/* Search + Actions */}
      <div className="flex flex-col sm:flex-row gap-3 justify-between">
        {onSearch && (
          <form onSubmit={handleSearch} className="flex gap-2 flex-1 max-w-md">
            <div className="relative flex-1">
              <HiOutlineSearch className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
              <input
                type="text"
                placeholder={searchPlaceholder}
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="input-field pl-9"
              />
            </div>
            <button type="submit" className="btn-primary">Buscar</button>
          </form>
        )}
        {actions && <div className="flex gap-2">{actions}</div>}
      </div>

      {/* Table */}
      <div className="overflow-x-auto bg-white rounded-xl border border-gray-200">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              {columns.map((col) => (
                <th key={col.key} className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                  {col.label}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {data.length === 0 ? (
              <tr>
                <td colSpan={columns.length} className="px-4 py-12 text-center text-gray-500">
                  {emptyMessage}
                </td>
              </tr>
            ) : (
              data.map((row, i) => (
                <tr key={row.id || i} className="hover:bg-gray-50 transition-colors">
                  {columns.map((col) => (
                    <td key={col.key} className="px-4 py-3 text-sm text-gray-700 whitespace-nowrap">
                      {col.render ? col.render(row) : row[col.key]}
                    </td>
                  ))}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      {pagination && pagination.totalPages > 1 && (
        <div className="flex items-center justify-between">
          <p className="text-sm text-gray-500">
            Mostrando {((pagination.page - 1) * pagination.limit) + 1} - {Math.min(pagination.page * pagination.limit, pagination.total)} de {pagination.total}
          </p>
          <div className="flex gap-1">
            <button
              onClick={() => onPageChange(pagination.page - 1)}
              disabled={pagination.page <= 1}
              className="p-2 rounded-lg hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <HiOutlineChevronLeft className="w-4 h-4" />
            </button>
            {Array.from({ length: Math.min(pagination.totalPages, 5) }, (_, i) => {
              const page = i + 1;
              return (
                <button
                  key={page}
                  onClick={() => onPageChange(page)}
                  className={`px-3 py-1 rounded-lg text-sm ${
                    page === pagination.page ? 'bg-vet-600 text-white' : 'hover:bg-gray-100'
                  }`}
                >
                  {page}
                </button>
              );
            })}
            <button
              onClick={() => onPageChange(pagination.page + 1)}
              disabled={pagination.page >= pagination.totalPages}
              className="p-2 rounded-lg hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <HiOutlineChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
