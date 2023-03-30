package golangbindings

import (
	"bytes"
	"crypto/ecdsa"
	"fmt"
	"math/big"
	"testing"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/accounts/abi/bind/backends"
	"github.com/ethereum/go-ethereum/core"
	"github.com/ethereum/go-ethereum/crypto"
)

func TestSolidityRoundTrip(t *testing.T) {
	sim, opts := newSimBackend(t)

	// DeployEcho is a generated function, embedded in the test target.
	_, _, echo, err := DeployEcho(opts, sim)
	if err != nil {
		t.Fatalf("DeployEcho(…, %T) error %v", sim, err)
	}
	sim.Commit()

	for _, payload := range []string{"a", "b", "hello world"} {
		got, err := echo.Echo(nil, payload)
		if want := fmt.Sprintf("Solidity: %s", payload); err != nil || got != want {
			t.Errorf("%T.Echo(nil, %q) got %q, err=%v; want %q, nil err", echo, payload, got, err, want)
		}
	}
}

// newSimBackend returns a simulated Ethereum backend running a genuine EVM for
// contract execution.
func newSimBackend(t *testing.T) (*backends.SimulatedBackend, *bind.TransactOpts) {
	alloc := make(core.GenesisAlloc)

	seed := []byte("hello world")
	entropy := bytes.NewReader(crypto.Keccak512(seed))
	key, err := ecdsa.GenerateKey(crypto.S256(), entropy)
	if err != nil {
		t.Fatalf("ecdsa.GenerateKey(crypto.S256, [deterministic entropy; Keccak512(%q)]): %v", seed, err)
	}

	txOpts, err := bind.NewKeyedTransactorWithChainID(key, big.NewInt(1337))
	if err != nil {
		t.Fatalf("bind.NewKeyedTransactorWithChainID(<new key>, sim-backend-id=1337): %v", err)
	}
	alloc[txOpts.From] = core.GenesisAccount{
		Balance: big.NewInt(1e18),
	}

	return backends.NewSimulatedBackend(alloc, 3e7), txOpts
}
