import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { petsAPI } from '../api/endpoints';
import DataTable from '../components/DataTable';
import LoadingSpinner from '../components/LoadingSpinner';
import toast from 'react-hot-toast';
import { HiOutlineEye, HiOutlinePencil, HiOutlineTrash } from 'react-icons/hi';

const speciesLabels = { DOG: '🐕 Perro', CAT: '🐱 Gato', BIRD: '🐦 Ave', REPTILE: '🦎 Reptil', RODENT: '🐹 Roedor', RABBIT: '🐇 Conejo', OTHER: '🐾 Otro' };
const speciesFilter = ['ALL', 'DOG', 'CAT', 'BIRD', 'REPTILE', 'RODENT', 'RABBIT', 'OTHER'];

export default function PetsPage() {
  const [pets, setPets] = useState([]);
  const [pagination, setPagination] = useState(null);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [species, setSpecies] = useState('ALL');

  useEffect(() => { loadPets(); }, [page, search, species]);

  const loadPets = async () => {
    try {
      const params = { page, limit: 20, search };
      if (species !== 'ALL') params.species = species;
      const { data } = await petsAPI.getAll(params);
      setPets(data.data);
      setPagination(data.pagination);
    } catch {
      toast.error('Error al cargar mascotas');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (!confirm('¿Eliminar esta mascota?')) return;
    try {
      await petsAPI.delete(id);
      toast.success('Mascota eliminada');
      loadPets();
    } catch {
      toast.error('Error al eliminar');
    }
  };

  const getAge = (birthDate) => {
    if (!birthDate) return '-';
    const diff = Date.now() - new Date(birthDate).getTime();
    const years = Math.floor(diff / (365.25 * 24 * 60 * 60 * 1000));
    const months = Math.floor((diff % (365.25 * 24 * 60 * 60 * 1000)) / (30.44 * 24 * 60 * 60 * 1000));
    if (years > 0) return `${years} año${years > 1 ? 's' : ''}${months > 0 ? ` ${months}m` : ''}`;
    return `${months} mes${months !== 1 ? 'es' : ''}`;
  };

  const columns = [
    {
      key: 'name', label: 'Mascota',
      render: (row) => (
        <Link to={`/pets/${row.id}`} className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-vet-50 flex items-center justify-center text-lg">
            {row.species === 'DOG' ? '🐕' : row.species === 'CAT' ? '🐱' : '🐾'}
          </div>
          <div>
            <p className="font-medium text-vet-600 hover:text-vet-800">{row.name}</p>
            <p className="text-xs text-gray-500">{row.breed || speciesLabels[row.species]?.split(' ')[1]}</p>
          </div>
        </Link>
      ),
    },
    { key: 'species', label: 'Especie', render: (row) => speciesLabels[row.species] || row.species },
    { key: 'age', label: 'Edad', render: (row) => getAge(row.birthDate) },
    { key: 'weight', label: 'Peso', render: (row) => row.weight ? `${row.weight} kg` : '-' },
    {
      key: 'client', label: 'Dueño',
      render: (row) => row.client ? (
        <Link to={`/clients/${row.client.id}`} className="text-sm text-blue-600 hover:text-blue-800">
          {row.client.firstName} {row.client.lastName}
        </Link>
      ) : '-',
    },
    {
      key: 'actions', label: 'Acciones',
      render: (row) => (
        <div className="flex gap-1">
          <Link to={`/pets/${row.id}`} className="p-1.5 hover:bg-gray-100 rounded-lg"><HiOutlineEye className="w-4 h-4 text-gray-500" /></Link>
          <Link to={`/pets/${row.id}`} className="p-1.5 hover:bg-gray-100 rounded-lg"><HiOutlinePencil className="w-4 h-4 text-blue-500" /></Link>
          <button onClick={() => handleDelete(row.id)} className="p-1.5 hover:bg-gray-100 rounded-lg"><HiOutlineTrash className="w-4 h-4 text-red-500" /></button>
        </div>
      ),
    },
  ];

  if (loading) return <LoadingSpinner />;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Mascotas</h1>
        <p className="text-gray-500">Registro de pacientes</p>
      </div>

      {/* Species Filter */}
      <div className="flex gap-2 flex-wrap">
        {speciesFilter.map(s => (
          <button key={s} onClick={() => { setSpecies(s); setPage(1); }}
            className={`px-3 py-1.5 rounded-full text-sm font-medium transition-colors ${species === s ? 'bg-vet-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}`}>
            {s === 'ALL' ? 'Todas' : speciesLabels[s]}
          </button>
        ))}
      </div>

      <DataTable columns={columns} data={pets} pagination={pagination} onPageChange={setPage} onSearch={setSearch} searchPlaceholder="Buscar por nombre, raza o dueño..." />
    </div>
  );
}
