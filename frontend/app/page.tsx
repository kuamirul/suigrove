'use client';

import { ConnectButton, useCurrentAccount } from '@mysten/dapp-kit';
import Link from 'next/link';

export default function Home() {
  const account = useCurrentAccount();

  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-8 p-8">
      <div className="text-center">
        <h1 className="text-5xl font-bold text-amber-800 mb-2">🌿 SuiGrove</h1>
        <p className="text-lg text-amber-700">
          A farming game on the Sui blockchain
        </p>
        <p className="text-sm text-gray-500 mt-1">
          Plant crops, wait for them to grow, harvest for GROVE tokens.
        </p>
      </div>

      <div className="flex flex-col items-center gap-4">
        <ConnectButton />
        {account && (
          <Link
            href="/farm"
            className="px-6 py-3 bg-green-600 hover:bg-green-700 text-white font-semibold rounded-lg transition-colors"
          >
            Go to My Farm →
          </Link>
        )}
      </div>

      {!account && (
        <p className="text-sm text-gray-400">
          Connect your Sui wallet to start farming
        </p>
      )}
    </main>
  );
}
